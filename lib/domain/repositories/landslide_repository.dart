import '../entities/landslide_zone.dart';

abstract class LandslideRepository {
  Future<List<LandslideZone>> getActiveZones();

  Future<List<LandslideZone>> getZonesByDistrict(String districtSlug);

  Future<List<LandslideZone>> getZonesBySeverity(String severity);
}
