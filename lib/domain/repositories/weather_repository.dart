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

  Future<void> cacheWeatherData(WeatherData data);

  Future<WeatherData?> getCachedWeatherData();

  Future<bool> isCacheValid();
}
