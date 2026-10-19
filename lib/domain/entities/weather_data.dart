import 'package:equatable/equatable.dart';

class WeatherData extends Equatable {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final String timezone;

  /// UTC offset of the loaded location at snapshot time (from the
  /// provider's `utcoffset` field). All parsed timestamps in this entity
  /// are provider-local wall-clock times; anything comparing them against
  /// "now" must convert via this offset (see WeatherAlertDeriver).
  final Duration providerOffset;
  final DateTime lastUpdated;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.timezone,
    this.providerOffset = const Duration(hours: 5, minutes: 30),
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        current,
        hourly,
        daily,
        timezone,
        providerOffset,
        lastUpdated,
      ];
}

class CurrentWeather extends Equatable {
  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final bool isDay;
  final double windSpeed;
  final double windDirection;
  final double humidity;
  final double precipitation;
  final double surfacePressure;
  final double cloudCover;
  final double uvIndex;

  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    this.isDay = true,
    required this.windSpeed,
    required this.windDirection,
    required this.humidity,
    required this.precipitation,
    required this.surfacePressure,
    required this.cloudCover,
    required this.uvIndex,
  });

  @override
  List<Object?> get props => [
        time,
        temperature,
        apparentTemperature,
        weatherCode,
        isDay,
        windSpeed,
        windDirection,
        humidity,
        precipitation,
        surfacePressure,
        cloudCover,
        uvIndex,
      ];
}

class HourlyWeather extends Equatable {
  final DateTime time;
  final double temperature;
  final double precipitationProbability;
  final double precipitation;
  final double windSpeed;
  final double windGusts;
  final int weatherCode;
  final double uvIndex;
  final double visibility;
  final double humidity;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.precipitation,
    required this.windSpeed,
    required this.windGusts,
    required this.weatherCode,
    required this.uvIndex,
    required this.visibility,
    required this.humidity,
  });

  @override
  List<Object?> get props => [
        time,
        temperature,
        precipitationProbability,
        precipitation,
        windSpeed,
        windGusts,
        weatherCode,
        uvIndex,
        visibility,
        humidity,
      ];
}

class DailyWeather extends Equatable {
  final DateTime time;
  final int weatherCode;
  final double temperatureMax;
  final double temperatureMin;
  final double precipitationSum;
  final double precipitationProbabilityMax;
  final double windSpeedMax;

  /// Peak daily gust (km/h). Nullable — older Hive cache entries and
  /// providers without gust data store null, and downstream copy must
  /// degrade to 'N/A' rather than reporting "0 km/h".
  final double? windGustsMax;
  final DateTime sunrise;
  final DateTime sunset;
  final double uvIndexMax;

  const DailyWeather({
    required this.time,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationSum,
    required this.precipitationProbabilityMax,
    required this.windSpeedMax,
    this.windGustsMax,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
  });

  @override
  List<Object?> get props => [
        time,
        weatherCode,
        temperatureMax,
        temperatureMin,
        precipitationSum,
        precipitationProbabilityMax,
        windSpeedMax,
        windGustsMax,
        sunrise,
        sunset,
        uvIndexMax,
      ];
}
