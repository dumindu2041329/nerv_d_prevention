import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/landslide_zone.dart';
import '../../domain/repositories/landslide_repository.dart';

class LandslideRepositoryImpl implements LandslideRepository {
  final SupabaseClient _client;

  LandslideRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<LandslideZone>> getActiveZones() async {
    final response = await _client
        .from('landslide_zones')
        .select()
        .eq('is_active', true)
        .order('severity', ascending: true);

    return _parseRows(response);
  }

  @override
  Future<List<LandslideZone>> getZonesByDistrict(String districtSlug) async {
    final response = await _client
        .from('landslide_zones')
        .select()
        .eq('is_active', true)
        .eq('district', districtSlug)
        .order('severity', ascending: true);

    return _parseRows(response);
  }

  @override
  Future<List<LandslideZone>> getZonesBySeverity(String severity) async {
    final response = await _client
        .from('landslide_zones')
        .select()
        .eq('is_active', true)
        .eq('severity', severity);

    return _parseRows(response);
  }

  List<LandslideZone> _parseRows(List<dynamic> rows) {
    return rows.map((r) {
      final row = r as Map<String, dynamic>;
      final rings = row['polygon_rings'] as List?;
      return LandslideZone(
        id: row['id'] as String,
        name: row['name'] as String,
        severity: row['severity'] as String,
        source: row['source'] as String,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        district: row['district'] as String?,
        polygonRings: rings
            ?.map((ring) => (ring as List)
                .map((c) => (c as num).toDouble())
                .toList())
            .cast<List<double>>()
            .toList(),
        isActive: row['is_active'] as bool? ?? true,
      );
    }).toList();
  }
}
