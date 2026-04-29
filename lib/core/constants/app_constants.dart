import 'package:flutter/material.dart';

class ApiConstants {
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1';
  static const String airQualityBaseUrl = 'https://air-quality-api.open-meteo.com/v1';
  static const String floodBaseUrl = 'https://flood-api.open-meteo.com/v1';
  static const String archiveBaseUrl = 'https://archive-api.open-meteo.com/v1';

  static const Duration currentWeatherCacheTtl = Duration(minutes: 10);
  static const Duration hourlyForecastCacheTtl = Duration(hours: 1);
  static const Duration dailyForecastCacheTtl = Duration(hours: 3);
  static const Duration airQualityCacheTtl = Duration(hours: 1);
  static const Duration floodDataCacheTtl = Duration(hours: 6);
  static const Duration geocodingCacheTtl = Duration(days: 7);

  static const int maxApiCallsPerDay = 10000;
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
