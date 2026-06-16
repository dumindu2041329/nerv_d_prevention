import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/alert.dart';

/// Client for the GDACS (Global Disaster Alert and Coordination System)
/// GeoJSON feed. GDACS is a free, no-key service that aggregates disaster
/// alerts from the UN, WMO, and partners worldwide — including cyclones,
/// earthquakes, floods, tsunamis, droughts and volcanic events.
///
/// The feed exposes a rolling 30-day window of events. We filter the
/// results down to events whose centroid falls within roughly 500 km of
/// Sri Lanka and map the GDACS `alertlevel` (Green / Orange / Red) onto
/// our [SeverityLevel] scale. Red is treated as an SOS (Critical) alert.
class SosAlertApiClient {
  final Dio _dio;

  SosAlertApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://www.gdacs.org/gdacsapi/api/events',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'nerv-d-prevention/1.0',
                },
              ),
            );

  /// Bounding box for Sri Lanka: (south, west, north, east).
  static const double _slSouth = 5.9167;
  static const double _slWest = 79.5333;
  static const double _slNorth = 9.8167;
  static const double _slEast = 81.8167;

  /// GDACS event types we care about:
  /// TC = Tropical Cyclone, EQ = Earthquake, FL = Flood,
  /// TS = Tsunami, VO = Volcano.
  static const String _eventTypes = 'TC,EQ,FL,TS,VO';

  /// Returns the list of active disaster events affecting or near
  /// Sri Lanka. Empty list on any error — the UI must be resilient to
  /// upstream outages (it falls back to cached + locally derived
  /// alerts via the repository).
  Future<List<Alert>> fetchSriLankaAlerts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/geojson',
        queryParameters: {
          'eventlist': _eventTypes,
          'fromdate': _isoDaysAgo(7),
        },
      );
      final data = response.data;
      if (data == null) return const [];

      final features = (data['features'] as List?) ?? const [];
      return features
          .cast<Map<String, dynamic>>()
          .map(_parseFeature)
          .whereType<Alert>()
          .where(_affectsSriLanka)
          .toList();
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// ISO 8601 UTC string for [daysAgo] days back. Used as a `fromdate`
  /// query param for GDACS, which only returns events newer than this.
  static String _isoDaysAgo(int days) {
    final d = DateTime.now().toUtc().subtract(Duration(days: days));
    return d.toIso8601String();
  }

  /// Map one GeoJSON feature to an [Alert]. Returns `null` if the
  /// feature is missing required fields.
  Alert? _parseFeature(Map<String, dynamic> feature) {
    final props = (feature['properties'] as Map?)?.cast<String, dynamic>();
    final geom = (feature['geometry'] as Map?)?.cast<String, dynamic>();
    if (props == null || geom == null) return null;

    final type = (props['eventtype'] as String? ?? '').toUpperCase();
    final name = props['name'] as String? ?? props['eventname'] as String?;
    final eventId = (props['eventid'] as num?)?.toInt();
    if (eventId == null) return null;

    final coords = _firstCoord(geom);
    if (coords == null) return null;

    final fromDate = props['fromdate'] as String?;
    final toDate = props['todate'] as String?;
    final issued = _parseDate(fromDate) ?? DateTime.now().toUtc();
    final expiry = _parseDate(toDate);

    final alertLevel = (props['alertlevel'] as String? ?? '').toLowerCase();
    final severity = _mapAlertLevel(alertLevel);

    final description = _buildDescription(props, coords);
    final headline = _buildHeadline(type, name, props);

    final lat = coords[1].toDouble();
    final lon = coords[0].toDouble();

    return Alert(
      id: 'gdacs-$eventId',
      type: _mapEventType(type),
      headline: headline,
      description: description,
      severity: severity,
      issuedTime: issued.toLocal(),
      expiryTime: expiry?.toLocal(),
      location: _locationLabel(props, lat, lon),
      metadata: {
        'source': 'GDACS',
        'eventId': eventId,
        'alertLevel': alertLevel,
        'eventType': type,
        'latitude': lat,
        'longitude': lon,
      },
    );
  }

  /// Extracts the first [longitude, latitude] pair from any supported
  /// GeoJSON geometry type (Point, LineString, Polygon, etc.).
  static List<num>? _firstCoord(Map<String, dynamic> geom) {
    final type = geom['type'] as String?;
    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    if (type == 'Point') {
      if (coords.length < 2) return null;
      return [coords[0] as num, coords[1] as num];
    }
    if (type == 'LineString' || type == 'MultiPoint') {
      final first = coords.first as List?;
      if (first == null || first.length < 2) return null;
      return [first[0] as num, first[1] as num];
    }
    if (type == 'Polygon' || type == 'MultiLineString') {
      final ring = (coords.first as List?)?.first as List?;
      if (ring == null || ring.length < 2) return null;
      return [ring[0] as num, ring[1] as num];
    }
    return null;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static SeverityLevel _mapAlertLevel(String level) {
    switch (level) {
      case 'red':
        return SeverityLevel.critical;
      case 'orange':
        return SeverityLevel.emergency;
      case 'green':
        return SeverityLevel.warning;
      default:
        return SeverityLevel.advisory;
    }
  }

  static String _mapEventType(String gdacsType) {
    switch (gdacsType) {
      case 'TC':
        return 'cyclone';
      case 'EQ':
        return 'earthquake';
      case 'FL':
        return 'flood';
      case 'TS':
        return 'tsunami';
      case 'VO':
        return 'volcano';
      case 'DR':
        return 'drought';
      default:
        return gdacsType.toLowerCase();
    }
  }

  static String _buildHeadline(
    String type,
    String? name,
    Map<String, dynamic> props,
  ) {
    final friendly = switch (type) {
      'TC' => 'Tropical Cyclone',
      'EQ' => 'Earthquake',
      'FL' => 'Flood',
      'TS' => 'Tsunami',
      'VO' => 'Volcanic Activity',
      'DR' => 'Drought',
      _ => type,
    };
    final loc = (props['country'] as String?) ?? name ?? 'Region';
    return '$friendly — $loc';
  }

  static String _buildDescription(
    Map<String, dynamic> props,
    List<num> coords,
  ) {
    final parts = <String>[];
    final severityText =
        (props['severitytext'] as Map?)?.cast<String, dynamic>();
    if (severityText != null) {
      final text = severityText['text'] as String?;
      if (text != null && text.isNotEmpty) parts.add(text);
    }
    final magnitude = props['magnitude'] as num?;
    final magnitudeUnit = props['magnitudeunit'] as String? ?? '';
    if (magnitude != null) {
      parts.add('Magnitude: ${magnitude.toStringAsFixed(1)} $magnitudeUnit');
    }
    final wind = (props['windspeed'] as num?)?.toDouble();
    if (wind != null) {
      parts.add('Wind: ${wind.toStringAsFixed(0)} km/h');
    }
    final lat = coords[1].toDouble().toStringAsFixed(2);
    final lon = coords[0].toDouble().toStringAsFixed(2);
    parts.add('Location: $lat, $lon');
    return parts.join('. ');
  }

  static String _locationLabel(
    Map<String, dynamic> props,
    double lat,
    double lon,
  ) {
    final country = props['country'] as String?;
    final region = props['region'] as String?;
    if (country != null && region != null) return '$region, $country';
    if (country != null) return country;
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  /// Keep only events whose centroid (point or first vertex) is within
  /// ~500 km of the Sri Lanka bounding box. This prevents flooding the
  /// UI with distant cyclones. 5° padding ≈ 555 km at the equator.
  static bool _affectsSriLanka(Alert a) {
    final meta = a.metadata;
    if (meta == null) return true; // don't drop on missing data
    final lat = (meta['latitude'] as num?)?.toDouble();
    final lon = (meta['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return true;
    const pad = 5.0;
    return lat >= _slSouth - pad &&
        lat <= _slNorth + pad &&
        lon >= _slWest - pad &&
        lon <= _slEast + pad;
  }
}
