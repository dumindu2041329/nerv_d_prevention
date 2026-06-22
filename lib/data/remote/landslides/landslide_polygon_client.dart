import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';

/// Landslide hazard polygons for Sri Lanka.
///
/// Primary source: NASA LHASA (Landslide Hazard Assessment for Situational
/// Awareness) WFS endpoint. Falls back to a curated NBRO-inspired set of
/// high-risk polygons for the central highlands and western escarpment when
/// the upstream feed is unreachable. The fallback is intentionally bundled so
/// the hazard layer remains useful offline.
class LandslidePolygonClient {
  late final Dio _dio;

  LandslidePolygonClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.nasaLhasaBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'nerv-d-prevention/1.0',
      },
    ));
  }

  /// Bounding box for Sri Lanka: (south, west, north, east).
  static const String _sriLankaBBox = '5.9167,79.5333,9.8167,81.8167';

  /// Returns landslide hazard polygons for Sri Lanka. Always returns at
  /// least the bundled NBRO fallback set.
  Future<List<LandslidePolygon>> getSriLankaPolygons() async {
    final remote = await _tryLhasa();
    if (remote.isNotEmpty) return remote;
    return nbroFallback();
  }

  Future<List<LandslidePolygon>> _tryLhasa() async {
    try {
      final response = await _dio.get(
        '/geoserver/ows',
        queryParameters: {
          'service': 'WFS',
          'version': '2.0.0',
          'request': 'GetFeature',
          'typeName': 'lhasa:nowcast',
          'outputFormat': 'application/json',
          'bbox': '$_sriLankaBBox,urn:ogc:def:crs:EPSG::4326',
        },
      );
      return _parseGeoJson(response.data);
    } catch (_) {
      return const [];
    }
  }

  List<LandslidePolygon> _parseGeoJson(dynamic data) {
    if (data is! Map<String, dynamic>) return const [];
    final features = data['features'] as List?;
    if (features == null) return const [];
    final out = <LandslidePolygon>[];
    for (final raw in features) {
      if (raw is! Map<String, dynamic>) continue;
      final geom = raw['geometry'] as Map<String, dynamic>?;
      if (geom == null) continue;
      final props =
          (raw['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
      final type = geom['type'] as String?;
      final coords = geom['coordinates'];
      if (coords is! List) continue;
      final rings = <List<LatLng>>[];
      if (type == 'Polygon') {
        for (final ring in coords) {
          final latlngs = _toLatLngRing(ring);
          if (latlngs != null && latlngs.length >= 3) rings.add(latlngs);
        }
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          if (poly is! List || poly.isEmpty) continue;
          final latlngs = _toLatLngRing(poly.first);
          if (latlngs != null && latlngs.length >= 3) rings.add(latlngs);
        }
      }
      for (final ring in rings) {
        out.add(LandslidePolygon(
          ring: ring,
          name: (props['name'] ??
                  props['location'] ??
                  props['id'] ??
                  'Landslide hazard')
              .toString(),
          severity: _severityFromProps(props),
          source: 'NASA LHASA',
        ));
      }
    }
    return out;
  }

  List<LatLng>? _toLatLngRing(dynamic ring) {
    if (ring is! List) return null;
    final points = <LatLng>[];
    for (final pair in ring) {
      if (pair is! List || pair.length < 2) continue;
      final lon = (pair[0] as num?)?.toDouble();
      final lat = (pair[1] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      points.add(LatLng(lat, lon));
    }
    if (points.length < 3) return null;
    // Close the ring if not already closed.
    if (points.first != points.last) {
      points.add(points.first);
    }
    return points;
  }

  static String _severityFromProps(Map<String, dynamic> props) {
    final raw = (props['susceptibility'] ??
            props['hazard'] ??
            props['risk'] ??
            props['class'] ??
            '')
        .toString()
        .toLowerCase();
    if (raw.contains('high') || raw.contains('4') || raw.contains('5')) {
      return 'emergency';
    }
    if (raw.contains('moderate') || raw.contains('medium') || raw.contains('3')) {
      return 'danger';
    }
    if (raw.contains('low') || raw.contains('2')) return 'caution';
    return 'advisory';
  }

  /// NBRO-inspired high-risk polygons. Shapes are simplified approximations
  /// of the published landslide hazard zonation for the central highlands,
  /// Knuckles range, and western escarpment — the regions where ~90% of
  /// Sri Lanka's recorded landslides occur.
  List<LandslidePolygon> nbroFallback() {
    return _staticZones
        .map((z) => LandslidePolygon(
              ring: z.points.map((p) => LatLng(p[0], p[1])).toList(),
              name: z.name,
              severity: z.severity,
              source: 'NBRO',
            ))
        .toList();
  }

  static const List<_Zone> _staticZones = [
    // Central highlands — highest frequency of recorded events.
    _Zone('Badulla Highlands', 'emergency', [
      [6.85, 80.92],
      [6.96, 81.08],
      [7.10, 81.14],
      [7.08, 80.96],
      [6.93, 80.83],
    ]),
    _Zone('Nuwara Eliya Massif', 'emergency', [
      [6.85, 80.62],
      [6.99, 80.78],
      [7.06, 80.66],
      [6.92, 80.52],
    ]),
    // Knuckles range — steep slopes, frequent events.
    _Zone('Matale Knuckles', 'danger', [
      [7.40, 80.55],
      [7.55, 80.70],
      [7.66, 80.60],
      [7.52, 80.45],
    ]),
    // Western escarpment — debris slides.
    _Zone('Ratnapura Escarpment', 'danger', [
      [6.60, 80.30],
      [6.74, 80.50],
      [6.86, 80.42],
      [6.72, 80.22],
    ]),
    _Zone('Kegalle Hills', 'danger', [
      [7.08, 80.28],
      [7.20, 80.45],
      [7.26, 80.30],
      [7.16, 80.18],
    ]),
    // Foothills and lower-elevation zones.
    _Zone('Kandy Foothills', 'caution', [
      [7.15, 80.55],
      [7.30, 80.70],
      [7.36, 80.55],
      [7.22, 80.44],
    ]),
    _Zone('Kalutara Western Slopes', 'caution', [
      [6.50, 80.10],
      [6.64, 80.30],
      [6.74, 80.20],
      [6.60, 80.00],
    ]),
    _Zone('Matara Highlands', 'caution', [
      [5.94, 80.50],
      [6.06, 80.66],
      [6.16, 80.56],
      [6.04, 80.42],
    ]),
  ];
}

class LandslidePolygon {
  /// Closed polygon ring (first == last).
  final List<LatLng> ring;
  final String name;
  final String severity; // advisory | caution | danger | emergency
  final String source;

  const LandslidePolygon({
    required this.ring,
    required this.name,
    required this.severity,
    required this.source,
  });
}

class _Zone {
  final String name;
  final String severity;
  final List<List<double>> points; // [lat, lon] pairs
  const _Zone(this.name, this.severity, this.points);
}