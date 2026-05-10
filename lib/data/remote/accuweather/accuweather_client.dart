import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';

class AccuWeatherClient {
  late final Dio _dio;

  AccuWeatherClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<AccuWeatherLocation?> getLocationKey({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        '/geoposition/$latitude/$longitude',
      );

      if (response.data == null) return null;
      return AccuWeatherLocation.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Location>> searchLocations(String query) async {
    try {
      final response = await _dio.get(
        '/location/$query',
      );

      if (response.data == null) return [];
      return (response.data as List).map((item) {
        final location = AccuWeatherLocation.fromJson(item);
        return Location(
          id: location.key,
          name: location.englishName,
          country: location.country?.englishName ?? '',
          admin1: location.administrativeArea?.englishName ?? '',
          latitude: location.geoPosition?.latitude ?? 0,
          longitude: location.geoPosition?.longitude ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    final location = await getLocationKey(
      latitude: latitude,
      longitude: longitude,
    );

    if (location == null) {
      throw Exception('Failed to get location key');
    }

    final current = await _getCurrentConditions(location.key);
    final hourly = await _getHourlyForecast(location.key);
    final daily = await _getDailyForecast(location.key);

    return WeatherData(
      current: current,
      hourly: hourly,
      daily: daily,
      timezone: location.timeZone?.standardName ?? 'UTC',
      lastUpdated: DateTime.now(),
    );
  }

  Future<CurrentWeather> _getCurrentConditions(String locationKey) async {
    final response = await _dio.get('/current/$locationKey');

    if (response.data == null || (response.data as List).isEmpty) {
      return _defaultCurrentWeather();
    }

    final data = response.data[0] as Map<String, dynamic>;
    return _parseCurrentConditions(data);
  }

  Future<List<HourlyWeather>> _getHourlyForecast(String locationKey) async {
    final response = await _dio.get('/hourly/$locationKey');

    if (response.data == null) return [];

    return _parseHourlyForecast(response.data as List);
  }

  Future<List<DailyWeather>> _getDailyForecast(String locationKey) async {
    final response = await _dio.get('/daily/$locationKey');

    if (response.data == null) return [];

    return _parseDailyForecast(response.data);
  }

  CurrentWeather _parseCurrentConditions(Map<String, dynamic> data) {
    final temp = data['Temperature']?['Metric'] ?? {};
    final feelsLike = data['RealFeelTemperature']?['Metric'] ?? {};
    final wind = data['Wind'] ?? {};
    final pressure = data['Pressure'] ?? {};
    final precip1hr = data['Precip1hr']?['Metric'] ?? {};

    return CurrentWeather(
      time: DateTime.parse(data['LocalObservationDateTime'] ?? DateTime.now().toIso8601String()),
      temperature: (temp['Value'] as num?)?.toDouble() ?? 0,
      apparentTemperature: (feelsLike['Value'] as num?)?.toDouble() ?? 0,
      weatherCode: (data['WeatherIcon'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['Speed']?['Value'] as num?)?.toDouble() ?? 0,
      windDirection: (wind['Direction']?['Degrees'] as num?)?.toDouble() ?? 0,
      humidity: (data['RelativeHumidity'] as num?)?.toDouble() ?? 0,
      precipitation: (precip1hr['Value'] as num?)?.toDouble() ?? 0,
      surfacePressure: (pressure['Value'] as num?)?.toDouble() ?? 0,
      cloudCover: (data['CloudCover'] as num?)?.toDouble() ?? 0,
      uvIndex: (data['UVIndex'] as num?)?.toDouble() ?? 0,
    );
  }

  List<HourlyWeather> _parseHourlyForecast(List forecastData) {
    final List<HourlyWeather> result = [];
    for (int i = 0; i < forecastData.length && i < 12; i++) {
      final data = forecastData[i] as Map<String, dynamic>;
      final temp = data['Temperature'] ?? {};
      final wind = data['Wind'] ?? {};
      final windGust = data['WindGust'] ?? {};
      final visibility = data['Visibility'] ?? {};
      final precip1hr = data['Precip1hr'] ?? {};

      result.add(HourlyWeather(
        time: DateTime.parse(data['DateTime'] ?? DateTime.now().toIso8601String()),
        temperature: (temp['Value'] as num?)?.toDouble() ?? 0,
        precipitationProbability: (data['PrecipitationProbability'] as num?)?.toDouble() ?? 0,
        precipitation: (precip1hr['Value'] as num?)?.toDouble() ?? 0,
        windSpeed: (wind['Speed']?['Value'] as num?)?.toDouble() ?? 0,
        windGusts: (windGust['Speed']?['Value'] as num?)?.toDouble() ?? 0,
        weatherCode: (data['WeatherIcon'] as num?)?.toInt() ?? 0,
        uvIndex: (data['UVIndex'] as num?)?.toDouble() ?? 0,
        visibility: (visibility['Value'] as num?)?.toDouble() ?? 10,
        humidity: (data['RelativeHumidity'] as num?)?.toDouble() ?? 50,
      ));
    }
    return result;
  }

  List<DailyWeather> _parseDailyForecast(Map<String, dynamic> data) {
    final forecasts = data['DailyForecasts'] as List?;
    if (forecasts == null) return [];

    final List<DailyWeather> result = [];
    for (int i = 0; i < forecasts.length; i++) {
      final forecast = forecasts[i] as Map<String, dynamic>;
      final day = forecast['Day'] ?? {};
      final temp = forecast['Temperature'] ?? {};
      final sun = forecast['Sun'] ?? {};

      result.add(DailyWeather(
        time: DateTime.parse(forecast['Date'] ?? DateTime.now().toIso8601String()),
        weatherCode: (day['Icon'] as num?)?.toInt() ?? 0,
        temperatureMax: (temp['Maximum']?['Value'] as num?)?.toDouble() ?? 0,
        temperatureMin: (temp['Minimum']?['Value'] as num?)?.toDouble() ?? 0,
        precipitationSum: (day['TotalLiquid']?['Value'] as num?)?.toDouble() ?? 0,
        precipitationProbabilityMax: (day['PrecipitationProbability'] as num?)?.toDouble() ?? 0,
        windSpeedMax: (day['Wind']?['Speed']?['Value'] as num?)?.toDouble() ?? 0,
        windGustsMax: (day['WindGust']?['Speed']?['Value'] as num?)?.toDouble() ?? 0,
        sunrise: DateTime.parse(sun['Rise'] ?? DateTime.now().toIso8601String()),
        sunset: DateTime.parse(sun['Set'] ?? DateTime.now().toIso8601String()),
        uvIndexMax: (day['UVIndex'] as num?)?.toDouble() ?? 0,
        shortwaveRadiationSum: 0,
      ));
    }
    return result;
  }

  CurrentWeather _defaultCurrentWeather() {
    return CurrentWeather(
      time: DateTime.now(),
      temperature: 0,
      apparentTemperature: 0,
      weatherCode: 0,
      windSpeed: 0,
      windDirection: 0,
      humidity: 0,
      precipitation: 0,
      surfacePressure: 0,
      cloudCover: 0,
      uvIndex: 0,
    );
  }
}

class AccuWeatherLocation {
  final String key;
  final String englishName;
  final AccuWeatherCountry? country;
  final AccuWeatherAdministrativeArea? administrativeArea;
  final AccuWeatherGeoPosition? geoPosition;
  final AccuWeatherTimeZone? timeZone;

  AccuWeatherLocation({
    required this.key,
    required this.englishName,
    this.country,
    this.administrativeArea,
    this.geoPosition,
    this.timeZone,
  });

  factory AccuWeatherLocation.fromJson(Map<String, dynamic> json) {
    return AccuWeatherLocation(
      key: json['Key'] ?? '',
      englishName: json['EnglishName'] ?? '',
      country: json['Country'] != null ? AccuWeatherCountry.fromJson(json['Country']) : null,
      administrativeArea: json['AdministrativeArea'] != null
          ? AccuWeatherAdministrativeArea.fromJson(json['AdministrativeArea'])
          : null,
      geoPosition: json['GeoPosition'] != null ? AccuWeatherGeoPosition.fromJson(json['GeoPosition']) : null,
      timeZone: json['TimeZone'] != null ? AccuWeatherTimeZone.fromJson(json['TimeZone']) : null,
    );
  }
}

class AccuWeatherCountry {
  final String englishName;

  AccuWeatherCountry({required this.englishName});

  factory AccuWeatherCountry.fromJson(Map<String, dynamic> json) {
    return AccuWeatherCountry(englishName: json['EnglishName'] ?? '');
  }
}

class AccuWeatherAdministrativeArea {
  final String englishName;

  AccuWeatherAdministrativeArea({required this.englishName});

  factory AccuWeatherAdministrativeArea.fromJson(Map<String, dynamic> json) {
    return AccuWeatherAdministrativeArea(englishName: json['EnglishName'] ?? '');
  }
}

class AccuWeatherGeoPosition {
  final double latitude;
  final double longitude;

  AccuWeatherGeoPosition({required this.latitude, required this.longitude});

  factory AccuWeatherGeoPosition.fromJson(Map<String, dynamic> json) {
    return AccuWeatherGeoPosition(
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AccuWeatherTimeZone {
  final String standardName;

  AccuWeatherTimeZone({required this.standardName});

  factory AccuWeatherTimeZone.fromJson(Map<String, dynamic> json) {
    return AccuWeatherTimeZone(standardName: json['StandardName'] ?? 'UTC');
  }
}