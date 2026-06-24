import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // API keys for weather + map providers are no longer stored in the
  // client. They live as Supabase Secrets and are accessed only by
  // Edge Functions. Keep Clerk publishable key here (it's designed to
  // be public).
  static String get clerkPublishableKey =>
      dotenv.get('CLERK_PUBLISHABLE_KEY', fallback: '');

  // Upstream provider URLs are retained for documentation only.
  // All client traffic now flows through Supabase Edge Functions.
  static const String weatherApiBaseUrl = 'https://api.weatherapi.com/v1';
  static const String mapTilerGeocodingBaseUrl = 'https://api.maptiler.com/geocoding';
  static const String overpassBaseUrl = 'https://overpass-api.de/api/interpreter';
  static const String nasaLhasaBaseUrl = 'https://lhasa.apps.opengeo.org';

  static const Duration currentWeatherCacheTtl = Duration(minutes: 10);
  static const Duration hourlyForecastCacheTtl = Duration(hours: 1);
  static const Duration dailyForecastCacheTtl = Duration(hours: 3);

  // ---------------------------------------------------------------------------
  // Map tile URLs — proxied through Supabase so provider keys stay server-side.
  //   The Supabase `tiles` Edge Function (supabase/functions/tiles/index.ts)
  //   reads MAPTILER_API_KEY / OWM_API_KEY from Supabase Secrets and forwards
  //   the request. Tile responses are CDN-cached for 1 hour.
  // ---------------------------------------------------------------------------

  static String get _supabaseBase =>
      dotenv.get('SUPABASE_URL').replaceAll(RegExp(r'/+$'), '');

  /// MapTiler hybrid basemap URL template. The `{z}/{x}/{y}` placeholders are
  /// substituted by `flutter_map` per tile.
  static String get mapTileHybrid =>
      '$_supabaseBase/functions/v1/tiles/maptiler/hybrid/{z}/{x}/{y}';

  // OWM tile layer variants used for the Select Layer map overlays.
  static String get owmPrecipitationOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/precipitation_new/{z}/{x}/{y}';
  static String get owmCloudsOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/clouds_new/{z}/{x}/{y}';
  static String get owmTempOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/temp_new/{z}/{x}/{y}';
  static String get owmWindOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/wind_new/{z}/{x}/{y}';
  static String get owmSnowOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/snow_new/{z}/{x}/{y}';
  static String get owmPressureOverlay =>
      '$_supabaseBase/functions/v1/tiles/owm/pressure_new/{z}/{x}/{y}';
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