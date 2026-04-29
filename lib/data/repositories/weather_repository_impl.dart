import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/weather_repository.dart';
import '../remote/open_meteo/open_meteo_client.dart';
import '../local/hive/hive_service.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final OpenMeteoClient _client;
  final HiveService _hiveService;

  WeatherRepositoryImpl({
    required OpenMeteoClient client,
    required HiveService hiveService,
  })  : _client = client,
        _hiveService = hiveService;

  @override
  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && await isCacheValid()) {
      final cached = await getCachedWeatherData();
      if (cached != null) return cached;
    }

    final data = await _client.getWeatherData(
      latitude: latitude,
      longitude: longitude,
    );

    await cacheWeatherData(data);
    return data;
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    return _client.searchLocations(query);
  }

  @override
  Future<Location?> getLocationFromGps() async {
    return null;
  }

  @override
  Future<void> cacheWeatherData(WeatherData data) async {
    await _hiveService.cacheWeatherData({
      'current': {
        'time': data.current.time.toIso8601String(),
        'temperature_2m': data.current.temperature,
        'apparent_temperature': data.current.apparentTemperature,
        'weather_code': data.current.weatherCode,
        'wind_speed_10m': data.current.windSpeed,
        'wind_direction_10m': data.current.windDirection,
        'relative_humidity_2m': data.current.humidity,
        'precipitation': data.current.precipitation,
        'surface_pressure': data.current.surfacePressure,
        'cloud_cover': data.current.cloudCover,
        'uv_index': data.current.uvIndex,
      },
      'timezone': data.timezone,
      'lastUpdated': data.lastUpdated.toIso8601String(),
    });
  }

  @override
  Future<WeatherData?> getCachedWeatherData() async {
    final data = _hiveService.getCachedWeatherData();
    if (data == null) return null;

    try {
      final currentData = data['current'] as Map<String, dynamic>;
      return WeatherData(
        current: CurrentWeather(
          time: DateTime.parse(currentData['time']),
          temperature: (currentData['temperature_2m'] as num).toDouble(),
          apparentTemperature: (currentData['apparent_temperature'] as num).toDouble(),
          weatherCode: (currentData['weather_code'] as num).toInt(),
          windSpeed: (currentData['wind_speed_10m'] as num).toDouble(),
          windDirection: (currentData['wind_direction_10m'] as num).toDouble(),
          humidity: (currentData['relative_humidity_2m'] as num).toDouble(),
          precipitation: (currentData['precipitation'] as num).toDouble(),
          surfacePressure: (currentData['surface_pressure'] as num).toDouble(),
          cloudCover: (currentData['cloud_cover'] as num).toDouble(),
          uvIndex: (currentData['uv_index'] as num).toDouble(),
        ),
        hourly: [],
        daily: [],
        timezone: data['timezone'] ?? 'UTC',
        lastUpdated: DateTime.parse(data['lastUpdated']),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = _hiveService.getCacheTimestamp();
    if (timestamp == null) return false;

    final elapsed = DateTime.now().difference(timestamp);
    return elapsed < ApiConstants.currentWeatherCacheTtl;
  }
}
