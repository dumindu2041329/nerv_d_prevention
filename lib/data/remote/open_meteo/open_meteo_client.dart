import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';

class OpenMeteoClient {
  late final Dio _dio;

  OpenMeteoClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.openMeteoBaseUrl}/forecast',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'weather_code',
          'wind_speed_10m',
          'wind_direction_10m',
          'relative_humidity_2m',
          'precipitation',
          'surface_pressure',
          'cloud_cover',
          'uv_index',
        ].join(','),
        'hourly': [
          'temperature_2m',
          'precipitation_probability',
          'precipitation',
          'wind_speed_10m',
          'wind_gusts_10m',
          'weather_code',
          'uv_index',
          'visibility',
          'relative_humidity_2m',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'apparent_temperature_max',
          'apparent_temperature_min',
          'precipitation_sum',
          'precipitation_probability_max',
          'wind_speed_10m_max',
          'wind_gusts_10m_max',
          'sunrise',
          'sunset',
          'uv_index_max',
          'shortwave_radiation_sum',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': AppConstants.forecastDays,
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
      },
    );

    final data = response.data;
    return _parseWeatherData(data);
  }

  Future<List<Location>> searchLocations(String query) async {
    final response = await _dio.get(
      '${ApiConstants.geocodingBaseUrl}/search',
      queryParameters: {
        'name': query,
        'count': 5,
        'language': 'en',
      },
    );

    final data = response.data;
    if (data['results'] == null) return [];

    return (data['results'] as List).map((item) {
      return Location(
        id: item['id'].toString(),
        name: item['name'] ?? '',
        country: item['country'],
        admin1: item['admin1'],
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final currentData = data['current'] as Map<String, dynamic>;
    final hourlyData = _parseHourlyData(data['hourly'] as Map<String, dynamic>);
    final dailyData = _parseDailyData(data['daily'] as Map<String, dynamic>);

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
      hourly: hourlyData,
      daily: dailyData,
      timezone: data['timezone'] ?? 'UTC',
      lastUpdated: DateTime.now(),
    );
  }

  List<HourlyWeather> _parseHourlyData(Map<String, dynamic> hourlyData) {
    final times = (hourlyData['time'] as List).cast<String>();
    final temperatures = (hourlyData['temperature_2m'] as List).cast<num>();
    final precipProbs = (hourlyData['precipitation_probability'] as List).cast<num>();
    final precips = (hourlyData['precipitation'] as List).cast<num>();
    final windSpeeds = (hourlyData['wind_speed_10m'] as List).cast<num>();
    final windGusts = (hourlyData['wind_gusts_10m'] as List).cast<num>();
    final weatherCodes = (hourlyData['weather_code'] as List).cast<num>();
    final uvIndices = (hourlyData['uv_index'] as List).cast<num>();
    final visibilities = (hourlyData['visibility'] as List).cast<num>();
    final humidities = (hourlyData['relative_humidity_2m'] as List).cast<num>();

    final List<HourlyWeather> result = [];
    for (int i = 0; i < times.length && i < 48; i++) {
      result.add(HourlyWeather(
        time: DateTime.parse(times[i]),
        temperature: temperatures[i].toDouble(),
        precipitationProbability: precipProbs[i].toDouble(),
        precipitation: precips[i].toDouble(),
        windSpeed: windSpeeds[i].toDouble(),
        windGusts: windGusts[i].toDouble(),
        weatherCode: weatherCodes[i].toInt(),
        uvIndex: uvIndices[i].toDouble(),
        visibility: (visibilities[i].toDouble() / 1000),
        humidity: humidities[i].toDouble(),
      ));
    }
    return result;
  }

  List<DailyWeather> _parseDailyData(Map<String, dynamic> dailyData) {
    final times = (dailyData['time'] as List).cast<String>();
    final weatherCodes = (dailyData['weather_code'] as List).cast<num>();
    final tempMaxs = (dailyData['temperature_2m_max'] as List).cast<num>();
    final tempMins = (dailyData['temperature_2m_min'] as List).cast<num>();
    final precipSums = (dailyData['precipitation_sum'] as List).cast<num>();
    final precipProbs = (dailyData['precipitation_probability_max'] as List).cast<num>();
    final windMaxs = (dailyData['wind_speed_10m_max'] as List).cast<num>();
    final gustMaxs = (dailyData['wind_gusts_10m_max'] as List).cast<num>();
    final sunrises = (dailyData['sunrise'] as List).cast<String>();
    final sunsets = (dailyData['sunset'] as List).cast<String>();
    final uvMaxs = (dailyData['uv_index_max'] as List).cast<num>();
    final radiations = (dailyData['shortwave_radiation_sum'] as List).cast<num>();

    final List<DailyWeather> result = [];
    for (int i = 0; i < times.length && i < 7; i++) {
      result.add(DailyWeather(
        time: DateTime.parse(times[i]),
        weatherCode: weatherCodes[i].toInt(),
        temperatureMax: tempMaxs[i].toDouble(),
        temperatureMin: tempMins[i].toDouble(),
        precipitationSum: precipSums[i].toDouble(),
        precipitationProbabilityMax: precipProbs[i].toDouble(),
        windSpeedMax: windMaxs[i].toDouble(),
        windGustsMax: gustMaxs[i].toDouble(),
        sunrise: DateTime.parse(sunrises[i]),
        sunset: DateTime.parse(sunsets[i]),
        uvIndexMax: uvMaxs[i].toDouble(),
        shortwaveRadiationSum: radiations[i].toDouble(),
      ));
    }
    return result;
  }
}
