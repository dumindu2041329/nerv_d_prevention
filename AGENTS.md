# NERV Disaster Prevention App — Agent Guide

**Last Updated:** May 28, 2026

This document provides context for AI agents working on the **nerv_d_prevention** project.

## Project Overview
This project is a Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. It is localized for **Sri Lanka** with 25 districts, DMC-style disaster alert categories, and monsoon awareness. It delivers real-time weather data, derived emergency-level alerts, rain radar mapping, and a timeline of weather events in a high-contrast dark UI.

## Key Technologies & Dependencies
- **Platform:** Flutter (iOS, Android, Web, Windows, macOS, Linux)
- **Language:** Dart 3 (SDK `^3.11.5`)
- **State Management:** [`flutter_bloc`](lib/presentation/blocs/) (^9.1.1)
- **Dependency Injection:** [`get_it`](lib/core/di/injection.dart) (^9.2.1)
- **Routing:** [`go_router`](lib/core/router/app_router.dart) (^17.2.3) — ShellRoute with 5 bottom tabs + push route
- **Network:** [`dio`](lib/data/remote/weatherapi/weather_api_client.dart) (^5.7.0) + `dio_cache_interceptor` (^3.5.0)
- **Local Storage:** [`hive_flutter`](lib/data/local/hive/hive_service.dart) (^1.1.0) — two boxes: `weather_cache` and `settings`
- **Location & Maps:** [`flutter_map`](lib/presentation/screens/map/map_screen.dart) (^8.3.0), [`latlong2`](lib/core/constants/app_sl_constants.dart) (^0.9.1), [`geolocator`](lib/data/repositories/weather_repository_impl.dart) (^14.0.2)
- **Weather Data:** **WeatherAPI.com** called directly from the Flutter client — single `/forecast.json` request returns current + hourly + daily (see [`lib/data/remote/weatherapi/weather_api_client.dart`](lib/data/remote/weatherapi/weather_api_client.dart))
- **Geocoding:** **MapTiler Geocoding API** for forward search and reverse geocoding (see [`lib/data/remote/maptiler/maptiler_geocoding_client.dart`](lib/data/remote/maptiler/maptiler_geocoding_client.dart))
- **Map Tiles:** MapTiler hybrid tiles — API key from `.env` via `flutter_dotenv`
- **Weather Overlay:** OpenWeatherMap precipitation tile overlay on all map screens — API key from `.env`
- **API Keys:** Stored in `.env` file (gitignored), loaded via `flutter_dotenv` in `main.dart`. Keys: `MAPTILER_API_KEY`, `OWM_API_KEY`, `WEATHERAPI_KEY`
- **Fonts:** `google_fonts` (^8.1.0) — Inter loaded at runtime; no bundled font assets

## Design System Principles
- **Clarity over decoration** — Minimalist, tactical operations interface. Every pixel serves information.
- **Urgency hierarchy** — Colour and size signal severity. Six severity levels: Critical → Emergency → Warning → Advisory → Info → Calm.
- **Night-mode first** — Dark theme is canonical; pure black `#000000` background. Light theme is secondary.
- **Privacy-first** — Zero tracking, no ads. Fully functional offline for cached data.
- **Typography:** Inter (via `google_fonts`) for all text. JetBrains Mono defined in PRD but **not currently used** in codebase.
- **Brand accent:** Cyan/teal `#00BCD4` (NOT orange as in some early PRD versions).
- **Severity colours:** Critical `#FF1744`, Emergency `#FF6D00`, Warning `#FFC400`, Advisory `#00E5FF`, Info `#69F0AE`, Calm `#42A5F5`.

## Architecture & Codebase Guidelines

### 1. Directory Structure
```
lib/
├── core/
│   ├── constants/        # Enums (app_colors.dart), API/UI constants (app_constants.dart), Sri Lanka data (app_sl_constants.dart), spacing, weather codes
│   ├── di/               # get_it service locator (injection.dart)
│   ├── router/           # GoRouter with ShellRoute (app_router.dart)
│   ├── theme/            # darkTheme() + lightTheme() + colour vision overrides (app_theme.dart)
│   └── utils/            # DateTime, String formatting, WeatherAlertDeriver (threshold-based alert derivation)
├── data/
│   ├── remote/
│   │   ├── weatherapi/      # WeatherApiClient (Dio → WeatherAPI.com /forecast.json)
│   │   └── maptiler/        # MaptilerGeocodingClient (forward search + reverse geocode)
│   ├── local/hive/          # HiveService (weather_cache + settings boxes)
│   └── repositories/        # WeatherRepositoryImpl, SettingsRepositoryImpl
├── domain/
│   ├── entities/         # WeatherData, Alert, Location, TimelineEvent, CrisisPin
│   └── repositories/     # Abstract WeatherRepository, SettingsRepository
├── presentation/
│   ├── blocs/weather/    # WeatherBloc + events + states (part files)
│   ├── blocs/settings/   # SettingsBloc + events + states (part files)
│   ├── screens/          # home, map, timeline, weather, weather_detail, settings, menu
│   └── widgets/          # main_scaffold, national_local_toggle, alert_banner, weather_card, forecast_card, location_search_widget, stale_data_banner
└── main.dart             # Entry point: loads dotenv, inits DI, SettingsBloc-driven theme
```

### 2. BLoC Pattern
- **WeatherBloc:** `WeatherInitial → WeatherLoading → WeatherLoaded/WeatherError`.
  - `LoadWeather(location: fixedLocation)` — uses fixed coordinates, **never touches GPS** (Island-wide mode)
  - `LoadWeather(useGps: true)` — resolves real GPS in background, updates when position arrives (Local mode)
  - `LoadWeather()` with no args — falls into GPS path (avoid; always be explicit)
  - `_FetchWeatherInBackground` — private event; fetches weather and emits `WeatherLoaded`
  - No stale-cache emit on tab switch — always emits `WeatherLoading` first to prevent cross-tab data leakage
- **SettingsBloc:** Single `SettingsState` with all preference fields. Events for each setting toggle/change.
- **No AlertBloc yet** — alerts are currently derived from weather thresholds by [`WeatherAlertDeriver`](lib/core/utils/weather_alert_deriver.dart). A separate `AlertBloc` is planned (see [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md)).
- **No usecases layer** — BLoCs call repositories directly. This is intentional simplification.

### 3. Island-wide vs Local Toggle
The `NationalLocalToggle` widget is shared across Home, Timeline, and Weather screens. It controls two distinct data modes:

| Mode | `LoadWeather` call | GPS | Map marker |
|------|-------------------|-----|------------|
| Island-wide | `LoadWeather(location: Location(id:'island_wide', lat:7.8731, lon:80.7718))` | Never | Hidden |
| Local | `LoadWeather(useGps: true)` | Always | Shown when GPS resolves |

**Critical rules:**
- Island-wide always uses Sri Lanka geographic center `LatLng(7.8731, 80.7718)` (near Dambulla) — NOT Colombo
- Each screen's `BlocProvider` must fire the island-wide `LoadWeather` on creation (default tab is Island-wide)
- Never fire `LoadWeather()` with no args from a screen — always be explicit about mode
- The BLoC emits `WeatherLoading` immediately on tab switch to prevent stale Local data appearing in Island-wide tab

### 4. UI Implementation
- **Do NOT use generic Material 3 defaults.** Use the theme from [`AppTheme.darkTheme()`/`lightTheme()`](lib/core/theme/app_theme.dart). Cards have 1px `#2A2A2A` border, 12dp radius, zero elevation on dark theme.
- **Colours:** Always reference severity colours via `SeverityLevel.color` getter. Use accent `#00BCD4` for interactive elements.
- **Many screens use inline styling** rather than theme tokens (e.g., `Colors.white.withValues(alpha: 0.5)`, `const Color(0xFF1A1A1A)`). Prefer theme tokens where available; use inline styling consistent with existing patterns where not.
- **Sri Lanka context:** Geographic center is `LatLng(7.8731, 80.7718)` (Dambulla) for Island-wide. Colombo `LatLng(6.9271, 79.8612)` is NOT the default anymore. Map bounds, districts, cities, and alert types are in [`app_sl_constants.dart`](lib/core/constants/app_sl_constants.dart).
- **Bottom nav:** 5 tabs — Home (`/home`), Timeline (`/timeline`), Map (`/map`), Weather (`/weather`), Menu (`/menu`). Defined in [`main_scaffold.dart`](lib/presentation/widgets/main_scaffold.dart).

### 5. Data Handling & API
- **Weather data pipeline:** `WeatherAPI.com → WeatherApiClient (Dio) → WeatherRepositoryImpl → WeatherBloc → UI`
- **Weather codes are WeatherAPI.com condition codes** (1000–1282), NOT AccuWeather codes (1–47) and NOT WMO codes. Use [`WeatherCodeMapping`](lib/core/constants/weather_codes.dart) for code→description/emoji mapping.
- **Cache:** `HiveService` with two Hive boxes: `weather_cache` (weather data) and `settings` (user preferences). Cache TTLs defined in `ApiConstants`: 10 min (current), 1 hour (hourly), 3 hours (daily).
- **Legacy cache support:** [`WeatherRepositoryImpl._tryLegacyCacheDeserialize()`](lib/data/repositories/weather_repository_impl.dart) handles older cache keys. Do not remove this.
- **Precipitation overlay** uses OpenWeatherMap tile API (`tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png`). Rendered as a `TileLayer` with 0.6 opacity on all map screens.
- **No backend server** — all API calls are made directly from the Flutter client.

### 6. Sri Lanka Localization
- **25 districts** in [`SLDistrict`](lib/core/constants/app_sl_constants.dart) enum with `displayName`, `province`, `center` coordinates.
- **6 DMC alert types** in [`SLAlertType`](lib/core/constants/app_sl_constants.dart) enum: flood, landslide, cyclone, lightning, coastalWarning, tsunami.
- **12 major cities** in [`SLCityConstants.majorCities`](lib/core/constants/app_sl_constants.dart).
- **Monsoon detection** via [`SLMonsoon.current()`](lib/core/constants/app_sl_constants.dart) from date.
- **Map constants:** `SLMapConstants.center = LatLng(7.8731, 80.7718)`, `initialZoom = 7.2`, used for Island-wide view.
- **National/Local toggle:** [`NationalLocalToggle`](lib/presentation/widgets/national_local_toggle.dart) widget — simple two-segment pill with "Island-wide" / "Local" labels. No district picker.

### 7. Files to Read Before Implementing Features
- **Product requirements + design:** [`NERV_Flutter_App_PRD.md`](NERV_Flutter_App_PRD.md) — the canonical PRD
- **DMC alert integration plan:** [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md) — architectural plan for real alert pipeline
- **SL localization plan:** [`plans/sri_lanka_localization_plan.md`](plans/sri_lanka_localization_plan.md) — completed localization implementation plan
- **How to start:** [`How to start.md`](How to start.md) — app startup commands

### 8. Known Issues & Gotchas
- [`weather_detail_screen.dart`](lib/presentation/screens/weather_detail/weather_detail_screen.dart) uses **hardcoded placeholder data** — needs wiring to WeatherBloc.
- `flutter_local_notifications` and `permission_handler` are in pubspec but **not wired up**.
- `drift` (SQLite) is NOT in pubspec — only Hive is used for local storage.
- `home_widget`, `firebase_messaging`, `injectable`/`injectable_generator` are NOT in pubspec — removed from early PRD plans.
- `freezed` and `json_serializable` are in dev_dependencies but entities use manual `Equatable` classes — no code generation is actually used.
- **Fonts are loaded via `google_fonts` at runtime** — first launch requires network for fonts. No bundled font assets in `assets/fonts/`.
- `assets/icons/` and `assets/images/` directories exist but contain only `.gitkeep` — no actual assets yet.
- The Menu screen in [`menu_screen.dart`](lib/presentation/screens/menu/menu_screen.dart) has hardcoded menu items (Language, Appearance, Notifications, Widget Settings) that are **non-functional** — display-only navigation placeholders.
- The "Weather data: Open-Meteo" footer text in [`settings_screen.dart`](lib/presentation/screens/settings/settings_screen.dart) is **stale/incorrect** — actual data comes from WeatherAPI.com.
- `connectivity_plus` is in pubspec but connectivity checks are not implemented — the app relies on cache fallback on network error.
- The `geocoding` package has been **removed** — reverse geocoding is handled by `MaptilerGeocodingClient`.
- The `accuweather_client.dart` file has been **deleted** — replaced by `weather_api_client.dart`.

### 9. What NOT to Do
- Do NOT use AccuWeather API or AccuWeather icon codes (1–47). The app uses WeatherAPI.com condition codes (1000–1282).
- Do NOT use Open-Meteo API or WMO weather codes.
- Do NOT hardcode API keys — all keys must come from `.env` via `ApiConstants` dotenv getters.
- Do NOT add a `usecases` layer — the architecture intentionally omits it.
- Do NOT use `drift`/SQLite — only `hive_flutter` is used for local storage.
- Do NOT add Firebase, AdMob, or any analytics/tracking SDK.
- Do NOT change the accent colour from `#00BCD4` (cyan) unless explicitly instructed.
- Do NOT remove the legacy cache deserialization fallback in WeatherRepositoryImpl.
- Do NOT use Japan-centric locations or terminology — the app is Sri Lanka-focused.
- Do NOT fire `LoadWeather()` with no arguments from screens — always pass `location:` for Island-wide or `useGps: true` for Local.
- Do NOT emit stale cached weather data when switching tabs — always emit `WeatherLoading` first on tab switch.
