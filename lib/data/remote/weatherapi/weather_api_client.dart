import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/weather_data.dart';

class WeatherApiClient {
  late final Dio _dio;

  WeatherApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.weatherApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// Single request returning current + 12h hourly + 5-day daily.
  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      '/forecast.json',
      queryParameters: {
        'key': ApiConstants.weatherApiKey,
        'q': '$latitude,$longitude',
        'days': 5,
        'aqi': 'no',
        'alerts': 'no',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final current = _parseCurrent(data['current']);
    final forecastDays = data['forecast']['forecastday'] as List;
    final hourly = _parseHourly(forecastDays);
    final daily = _parseDaily(forecastDays);
    final timezone = data['location']['tz_id'] as String? ?? 'UTC';

    return WeatherData(
      current: current,
      hourly: hourly,
      daily: daily,
      timezone: timezone,
      lastUpdated: DateTime.now(),
    );
  }

  CurrentWeather _parseCurrent(Map<String, dynamic> c) {
    return CurrentWeather(
      time: DateTime.now(),
      temperature: (c['temp_c'] as num).toDouble(),
      apparentTemperature: (c['feelslike_c'] as num).toDouble(),
      weatherCode: (c['condition']['code'] as num).toInt(),
      isDay: (c['is_day'] as num? ?? 1) == 1,
      windSpeed: (c['wind_kph'] as num).toDouble(),
      windDirection: (c['wind_degree'] as num).toDouble(),
      humidity: (c['humidity'] as num).toDouble(),
      precipitation: (c['precip_mm'] as num).toDouble(),
      surfacePressure: (c['pressure_mb'] as num).toDouble(),
      cloudCover: (c['cloud'] as num).toDouble(),
      uvIndex: (c['uv'] as num).toDouble(),
    );
  }

  List<HourlyWeather> _parseHourly(List forecastDays) {
    final result = <HourlyWeather>[];
    final now = DateTime.now();

    for (final day in forecastDays) {
      for (final h in (day['hour'] as List)) {
        final time = DateTime.parse(h['time'] as String);
        if (time.isBefore(now)) continue;
        if (result.length >= 12) break;
        result.add(HourlyWeather(
          time: time,
          temperature: (h['temp_c'] as num).toDouble(),
          precipitationProbability: (h['chance_of_rain'] as num).toDouble(),
          precipitation: (h['precip_mm'] as num).toDouble(),
          windSpeed: (h['wind_kph'] as num).toDouble(),
          windGusts: (h['gust_kph'] as num).toDouble(),
          weatherCode: (h['condition']['code'] as num).toInt(),
          uvIndex: (h['uv'] as num).toDouble(),
          visibility: (h['vis_km'] as num).toDouble(),
          humidity: (h['humidity'] as num).toDouble(),
        ));
      }
      if (result.length >= 12) break;
    }
    return result;
  }

  List<DailyWeather> _parseDaily(List forecastDays) {
    return forecastDays.map((day) {
      final d = day['day'] as Map<String, dynamic>;
      final astro = day['astro'] as Map<String, dynamic>;
      final date = DateTime.parse(day['date'] as String);

      return DailyWeather(
        time: date,
        weatherCode: (d['condition']['code'] as num).toInt(),
        temperatureMax: (d['maxtemp_c'] as num).toDouble(),
        temperatureMin: (d['mintemp_c'] as num).toDouble(),
        precipitationSum: (d['totalprecip_mm'] as num).toDouble(),
        precipitationProbabilityMax: (d['daily_chance_of_rain'] as num).toDouble(),
        windSpeedMax: (d['maxwind_kph'] as num).toDouble(),
        windGustsMax: 0,
        sunrise: _parseAstroTime(date, astro['sunrise'] as String),
        sunset: _parseAstroTime(date, astro['sunset'] as String),
        uvIndexMax: (d['uv'] as num).toDouble(),
        shortwaveRadiationSum: 0,
      );
    }).toList();
  }

  DateTime _parseAstroTime(DateTime date, String timeStr) {
    try {
      // Format: "06:30 AM"
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts[1] == 'AM' && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }
}
