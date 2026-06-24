import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/location.dart';

/// Calls the `geocode` Supabase Edge Function, which proxies the
/// MapTiler Geocoding API. The MapTiler key lives in Supabase Secrets
/// and is never bundled in the APK.
///
/// See `supabase/functions/geocode/index.ts`.
class MaptilerGeocodingClient {
  final SupabaseClient _client;

  MaptilerGeocodingClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Forward geocoding: search by place name.
  Future<List<Location>> searchLocations(String query) async {
    try {
      final response = await _client.functions.invoke(
        'geocode',
        body: {'q': query, 'limit': 5},
      );
      if (response.status != 200) return const [];
      final data = response.data;
      if (data is! Map<String, dynamic>) return const [];
      return _parseFeatures(data);
    } catch (_) {
      return const [];
    }
  }

  /// Reverse geocoding: coordinates → place name.
  Future<Location?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _client.functions.invoke(
        'geocode',
        body: {'latitude': latitude, 'longitude': longitude},
      );
      if (response.status != 200) return null;
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final features = _parseFeatures(data);
      return features.isNotEmpty ? features.first : null;
    } catch (_) {
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