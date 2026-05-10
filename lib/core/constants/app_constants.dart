import 'package:flutter/material.dart';

class ApiConstants {
  static const String backendBaseUrl = 'http://localhost:8080';

  static const Duration currentWeatherCacheTtl = Duration(minutes: 10);
  static const Duration hourlyForecastCacheTtl = Duration(hours: 1);
  static const Duration dailyForecastCacheTtl = Duration(hours: 3);

  static const int maxApiCallsPerDay = 50;
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
