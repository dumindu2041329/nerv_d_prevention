import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/weather_repository.dart';
import '../remote/accuweather/accuweather_client.dart';
import '../local/hive/hive_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class WeatherRepositoryImpl implements WeatherRepository {
  final AccuWeatherClient _client;
  final HiveService _hiveService;

  WeatherRepositoryImpl({
    required AccuWeatherClient client,
    required HiveService hiveService,
  }) : _client = client,
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      String name = 'Current Location';
      String? country;
      String? admin1;

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          name =
              place.locality ??
              place.subAdministrativeArea ??
              place.name ??
              'Current Location';
          country = place.country;
          admin1 = place.administrativeArea;
        }
      } catch (e) {
        // Fallback to coordinates
      }

      return Location(
        id: 'gps',
        name: name,
        country: country,
        admin1: admin1,
        latitude: position.latitude,
        longitude: position.longitude,
        isGps: true,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Cache (de)serialization with full hourly + daily support ─────────

  @override
  Future<void> cacheWeatherData(WeatherData data) async {
    await _hiveService.cacheWeatherData({
      'current': _serializeCurrent(data.current),
      'hourly': data.hourly.map(_serializeHourly).toList(),
      'daily': data.daily.map(_serializeDaily).toList(),
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
      final hourlyData = data['hourly'] as List?;
      final dailyData = data['daily'] as List?;
      final timezone = (data['timezone'] as String?) ?? 'UTC';
      final lastUpdated = DateTime.parse(data['lastUpdated'] as String);

      return WeatherData(
        current: _deserializeCurrent(currentData),
        hourly:
            hourlyData
                ?.map((e) => _deserializeHourly(e as Map<String, dynamic>))
                .toList() ??
            [],
        daily:
            dailyData
                ?.map((e) => _deserializeDaily(e as Map<String, dynamic>))
                .toList() ??
            [],
        timezone: timezone,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      // Fallback to old-format cache (current only)
      return _tryLegacyCacheDeserialize(data);
    }
  }

  /// Attempts to deserialize the older cache format which only stored
  /// 'current' with different key names (Open-Meteo style).
  WeatherData? _tryLegacyCacheDeserialize(Map<String, dynamic> data) {
    try {
      final currentMap = data['current'] as Map<String, dynamic>;
      return WeatherData(
        current: CurrentWeather(
          time: DateTime.parse(currentMap['time'] as String),
          temperature:
              (currentMap['temperature_2m'] as num?)?.toDouble() ??
              (currentMap['temperature'] as num?)?.toDouble() ??
              0,
          apparentTemperature:
              (currentMap['apparent_temperature'] as num?)?.toDouble() ??
              (currentMap['apparentTemperature'] as num?)?.toDouble() ??
              0,
          weatherCode:
              (currentMap['weather_code'] as num?)?.toInt() ??
              (currentMap['weatherCode'] as num?)?.toInt() ??
              0,
          windSpeed:
              (currentMap['wind_speed_10m'] as num?)?.toDouble() ??
              (currentMap['windSpeed'] as num?)?.toDouble() ??
              0,
          windDirection:
              (currentMap['wind_direction_10m'] as num?)?.toDouble() ??
              (currentMap['windDirection'] as num?)?.toDouble() ??
              0,
          humidity:
              (currentMap['relative_humidity_2m'] as num?)?.toDouble() ??
              (currentMap['humidity'] as num?)?.toDouble() ??
              0,
          precipitation: (currentMap['precipitation'] as num?)?.toDouble() ?? 0,
          surfacePressure:
              (currentMap['surface_pressure'] as num?)?.toDouble() ??
              (currentMap['surfacePressure'] as num?)?.toDouble() ??
              0,
          cloudCover:
              (currentMap['cloud_cover'] as num?)?.toDouble() ??
              (currentMap['cloudCover'] as num?)?.toDouble() ??
              0,
          uvIndex:
              (currentMap['uv_index'] as num?)?.toDouble() ??
              (currentMap['uvIndex'] as num?)?.toDouble() ??
              0,
        ),
        hourly: [],
        daily: [],
        timezone: (data['timezone'] as String?) ?? 'UTC',
        lastUpdated: DateTime.parse(data['lastUpdated'] as String),
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

  @override
  Location? getCachedLocation() {
    return _hiveService.getCachedLocation();
  }

  @override
  Future<void> cacheLocation(Location location) async {
    await _hiveService.cacheLocation(location);
  }

  // ── Private serializers ─────────────────────────────────────────────

  Map<String, dynamic> _serializeCurrent(CurrentWeather c) => {
    'time': c.time.toIso8601String(),
    'temperature': c.temperature,
    'apparentTemperature': c.apparentTemperature,
    'weatherCode': c.weatherCode,
    'windSpeed': c.windSpeed,
    'windDirection': c.windDirection,
    'humidity': c.humidity,
    'precipitation': c.precipitation,
    'surfacePressure': c.surfacePressure,
    'cloudCover': c.cloudCover,
    'uvIndex': c.uvIndex,
  };

  CurrentWeather _deserializeCurrent(Map<String, dynamic> m) => CurrentWeather(
    time: DateTime.parse(m['time'] as String),
    temperature: (m['temperature'] as num).toDouble(),
    apparentTemperature: (m['apparentTemperature'] as num).toDouble(),
    weatherCode: (m['weatherCode'] as num).toInt(),
    windSpeed: (m['windSpeed'] as num).toDouble(),
    windDirection: (m['windDirection'] as num).toDouble(),
    humidity: (m['humidity'] as num).toDouble(),
    precipitation: (m['precipitation'] as num).toDouble(),
    surfacePressure: (m['surfacePressure'] as num).toDouble(),
    cloudCover: (m['cloudCover'] as num).toDouble(),
    uvIndex: (m['uvIndex'] as num).toDouble(),
  );

  Map<String, dynamic> _serializeHourly(HourlyWeather h) => {
    'time': h.time.toIso8601String(),
    'temperature': h.temperature,
    'precipitationProbability': h.precipitationProbability,
    'precipitation': h.precipitation,
    'windSpeed': h.windSpeed,
    'windGusts': h.windGusts,
    'weatherCode': h.weatherCode,
    'uvIndex': h.uvIndex,
    'visibility': h.visibility,
    'humidity': h.humidity,
  };

  HourlyWeather _deserializeHourly(Map<String, dynamic> m) => HourlyWeather(
    time: DateTime.parse(m['time'] as String),
    temperature: (m['temperature'] as num).toDouble(),
    precipitationProbability: (m['precipitationProbability'] as num).toDouble(),
    precipitation: (m['precipitation'] as num).toDouble(),
    windSpeed: (m['windSpeed'] as num).toDouble(),
    windGusts: (m['windGusts'] as num).toDouble(),
    weatherCode: (m['weatherCode'] as num).toInt(),
    uvIndex: (m['uvIndex'] as num).toDouble(),
    visibility: (m['visibility'] as num).toDouble(),
    humidity: (m['humidity'] as num).toDouble(),
  );

  Map<String, dynamic> _serializeDaily(DailyWeather d) => {
    'time': d.time.toIso8601String(),
    'weatherCode': d.weatherCode,
    'temperatureMax': d.temperatureMax,
    'temperatureMin': d.temperatureMin,
    'precipitationSum': d.precipitationSum,
    'precipitationProbabilityMax': d.precipitationProbabilityMax,
    'windSpeedMax': d.windSpeedMax,
    'windGustsMax': d.windGustsMax,
    'sunrise': d.sunrise.toIso8601String(),
    'sunset': d.sunset.toIso8601String(),
    'uvIndexMax': d.uvIndexMax,
    'shortwaveRadiationSum': d.shortwaveRadiationSum,
  };

  DailyWeather _deserializeDaily(Map<String, dynamic> m) => DailyWeather(
    time: DateTime.parse(m['time'] as String),
    weatherCode: (m['weatherCode'] as num).toInt(),
    temperatureMax: (m['temperatureMax'] as num).toDouble(),
    temperatureMin: (m['temperatureMin'] as num).toDouble(),
    precipitationSum: (m['precipitationSum'] as num).toDouble(),
    precipitationProbabilityMax: (m['precipitationProbabilityMax'] as num)
        .toDouble(),
    windSpeedMax: (m['windSpeedMax'] as num).toDouble(),
    windGustsMax: (m['windGustsMax'] as num).toDouble(),
    sunrise: DateTime.parse(m['sunrise'] as String),
    sunset: DateTime.parse(m['sunset'] as String),
    uvIndexMax: (m['uvIndexMax'] as num).toDouble(),
    shortwaveRadiationSum: (m['shortwaveRadiationSum'] as num).toDouble(),
  );
}
