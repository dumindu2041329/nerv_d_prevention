import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get mapTilerApiKey => dotenv.get('MAPTILER_API_KEY');
  static String get owmApiKey => dotenv.get('OWM_API_KEY');
  static String get weatherApiKey => dotenv.get('WEATHERAPI_KEY');

  static const String weatherApiBaseUrl = 'https://api.weatherapi.com/v1';
  static const String mapTilerGeocodingBaseUrl = 'https://api.maptiler.com/geocoding';

  static const Duration currentWeatherCacheTtl = Duration(minutes: 10);
  static const Duration hourlyForecastCacheTtl = Duration(hours: 1);
  static const Duration dailyForecastCacheTtl = Duration(hours: 3);

  static String get mapTileHybrid =>
      'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';

  static String get owmPrecipitationOverlay =>
      'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$owmApiKey';

  // OWM tile layer variants used for the Select Layer map overlays.
  static String get owmCloudsOverlay =>
      'https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=$owmApiKey';

  static String get owmTempOverlay =>
      'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=$owmApiKey';

  static String get owmWindOverlay =>
      'https://tile.openweathermap.org/map/wind_new/{z}/{x}/{y}.png?appid=$owmApiKey';

  static String get owmSnowOverlay =>
      'https://tile.openweathermap.org/map/snow_new/{z}/{x}/{y}.png?appid=$owmApiKey';

  static String get owmPressureOverlay =>
      'https://tile.openweathermap.org/map/pressure_new/{z}/{x}/{y}.png?appid=$owmApiKey';
}

class AppConstants {
  static const double minTouchTarget = 48.0;
  static const double focusRingWidth = 2.0;
  static const Color focusRingColor = Color(0xFF00E5FF);
  static const double minContrastRatio = 4.5;

  static const int forecastDays = 7;
  static const int hourlyForecastHours = 24;
  static const int timelineHours = 72;

  static const double screenMaxWidth = 600.0;
  static const double bottomNavHeight = 64.0;
  static const double topBarHeight = 56.0;
}
