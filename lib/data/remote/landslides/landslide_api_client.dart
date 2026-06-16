import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';

/// Landslide risk data sourced from OpenStreetMap via the Overpass API.
///
/// Queries for OSM features tagged with `geological=landslide` within the
/// bounding box of Sri Lanka. Elements are normalised to point locations:
/// nodes use their own coordinates, ways/relations use the centroid
/// returned by Overpass.
class LandslideApiClient {
  late final Dio _dio;

  LandslideApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.overpassBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'nerv-d-prevention/1.0',
      },
    ));
  }

  /// Bounding box for Sri Lanka: (south, west, north, east).
  static const String _sriLankaBBox = '5.9167,79.5333,9.8167,81.8167';

  /// Fetches landslide features within Sri Lanka.
  ///
  /// Returns an empty list on error so the UI can fall back to mock data
  /// or render a calm state.
  Future<List<LandslideFeature>> getSriLankaLandslides() async {
    final query = '''
[out:json][timeout:25];
(
  node["geological"="landslide"]($_sriLankaBBox);
  way["geological"="landslide"]($_sriLankaBBox);
  relation["geological"="landslide"]($_sriLankaBBox);
  node["landuse"="landslide"]($_sriLankaBBox);
  way["landuse"="landslide"]($_sriLankaBBox);
);
out center 200;
''';

    try {
      final response = await _dio.post(
        '',
        data: {'data': query},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final data = response.data as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? const [];
      return elements
          .map((e) => _parseElement(e as Map<String, dynamic>))
          .whereType<LandslideFeature>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  LandslideFeature? _parseElement(Map<String, dynamic> e) {
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final type = e['type'] as String?;
    double? lat;
    double? lon;
    if (type == 'node') {
      lat = (e['lat'] as num?)?.toDouble();
      lon = (e['lon'] as num?)?.toDouble();
    } else {
      final center = e['center'] as Map?;
      if (center != null) {
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }
    }
    if (lat == null || lon == null) return null;
    return LandslideFeature(
      location: LatLng(lat, lon),
      name: tags['name'] as String? ?? tags['name:en'] as String?,
      severity: _parseSeverity(tags),
      tags: tags,
    );
  }

  /// Derive a coarse severity from OSM tags. Real NBRO data is much richer
  /// (4 classes mapped to GN divisions); this maps common tag hints onto
  /// our 4-level legend.
  static String _parseSeverity(Map<String, dynamic> tags) {
    final material = (tags['material'] as String? ?? '').toLowerCase();
    final note = (tags['note'] as String? ?? '').toLowerCase();
    final desc = (tags['description'] as String? ?? '').toLowerCase();
    final blob = '$material $note $desc';

    if (blob.contains('active') || blob.contains('recent')) return 'emergency';
    if (blob.contains('high') || blob.contains('major')) return 'danger';
    if (blob.contains('moderate') || blob.contains('medium')) return 'caution';
    return 'advisory';
  }
}

class LandslideFeature {
  final LatLng location;
  final String? name;
  final String severity;
  final Map<String, dynamic> tags;

  const LandslideFeature({
    required this.location,
    required this.name,
    required this.severity,
    required this.tags,
  });
}
