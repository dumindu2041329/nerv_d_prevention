import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/location.dart';

class MaptilerGeocodingClient {
  late final Dio _dio;

  MaptilerGeocodingClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.mapTilerGeocodingBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// Forward geocoding: search by place name.
  Future<List<Location>> searchLocations(String query) async {
    try {
      final response = await _dio.get(
        '/${Uri.encodeComponent(query)}.json',
        queryParameters: {'key': ApiConstants.mapTilerApiKey, 'limit': 5},
      );
      return _parseFeatures(response.data);
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocoding: coordinates → place name.
  Future<Location?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/$longitude,$latitude.json',
        queryParameters: {
          'key': ApiConstants.mapTilerApiKey,
          'limit': 1,
          'types': 'municipality,locality,place',
        },
      );
      final features = _parseFeatures(response.data);
      return features.isNotEmpty ? features.first : null;
    } catch (e) {
      return null;
    }
  }

  List<Location> _parseFeatures(Map<String, dynamic> data) {
    final features = data['features'] as List?;
    if (features == null) return [];

    return features.map((f) {
      final center = f['center'] as List?;
      final lon = (center?[0] as num?)?.toDouble() ?? 0;
      final lat = (center?[1] as num?)?.toDouble() ?? 0;
      final name = (f['text'] as String?) ?? (f['place_name'] as String?) ?? '';

      // Extract country and region from context hierarchy
      String? country;
      String? admin1;
      final context = f['context'] as List?;
      if (context != null) {
        for (final ctx in context) {
          final id = (ctx['id'] as String?) ?? '';
          if (id.startsWith('country.')) {
            country = ctx['text'] as String?;
          } else if (id.startsWith('region.') || id.startsWith('subregion.')) {
            admin1 ??= ctx['text'] as String?;
          }
        }
      }

      return Location(
        id: (f['id'] as String?) ?? '$lon,$lat',
        name: name,
        country: country,
        admin1: admin1,
        latitude: lat,
        longitude: lon,
      );
    }).toList();
  }
}
