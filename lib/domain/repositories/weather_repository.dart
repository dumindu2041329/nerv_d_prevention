import '../entities/weather_data.dart';
import '../entities/location.dart';

abstract class WeatherRepository {
  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  });

  Future<List<Location>> searchLocations(String query);

  Future<Location?> getLocationFromGps();

  Future<void> cacheWeatherData(
    WeatherData data, {
    required double latitude,
    required double longitude,
  });

  Future<WeatherData?> getCachedWeatherData({
    required double latitude,
    required double longitude,
  });

  Future<bool> isCacheValid({
    required double latitude,
    required double longitude,
  });

  Location? getCachedLocation();

  Future<void> cacheLocation(Location location);
}
