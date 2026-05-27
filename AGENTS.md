# NERV Disaster Prevention App — Agent Guide

**Last Updated:** May 27, 2026

This document provides context for AI agents working on the **nerv_d_prevention** project.

## Project Overview
This project is a Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. It is localized for **Sri Lanka** with 25 districts, DMC-style disaster alert categories, and monsoon awareness. It delivers real-time weather data, derived emergency-level alerts, rain radar mapping, and a timeline of weather events in a high-contrast dark UI.

## Key Technologies & Dependencies
- **Platform:** Flutter (iOS, Android, Web, Windows, macOS, Linux)
- **Language:** Dart 3 (SDK `^3.11.5`)
- **State Management:** [`flutter_bloc`](lib/presentation/blocs/) (^9.1.1)
- **Dependency Injection:** [`get_it`](lib/core/di/injection.dart) (^9.2.1)
- **Routing:** [`go_router`](lib/core/router/app_router.dart) (^17.2.2) — ShellRoute with 5 bottom tabs + push route
- **Network:** [`dio`](lib/data/remote/accuweather/accuweather_client.dart) (^5.7.0) + `dio_cache_interceptor` (^3.5.0)
- **Local Storage:** [`hive_flutter`](lib/data/local/hive/hive_service.dart) (^1.1.0) — two boxes: `weather_cache` and `settings`
- **Location & Maps:** [`flutter_map`](lib/presentation/screens/map/map_screen.dart) (^8.3.0), [`latlong2`](lib/core/constants/app_sl_constants.dart) (^0.9.1), [`geolocator`](lib/data/repositories/weather_repository_impl.dart) (^14.0.2), [`geocoding`](lib/data/repositories/weather_repository_impl.dart) (^4.0.0)
- **Weather Data:** **AccuWeather API** via Dart Shelf backend proxy — NOT Open-Meteo directly (see [`backend/lib/server.dart`](backend/lib/server.dart))
- **Map Tiles:** CartoDB Dark Matter (free, no API key)
- **Rain Radar:** RainViewer public API (free, no API key)
- **Fonts:** `google_fonts` (^8.0.2) — Inter loaded at runtime; no bundled font assets
- **Backend:** Dart Shelf server (shelf ^1.4.1, shelf_router ^1.1.4, dio ^5.4.0, dotenv ^4.2.0)

## Design System Principles
- **Clarity over decoration** — Minimalist, tactical operations interface. Every pixel serves information.
- **Urgency hierarchy** — Colour and size signal severity. Six severity levels: Critical → Emergency → Warning → Advisory → Info → Calm.
- **Night-mode first** — Dark theme is canonical; pure black `#000000` background. Light theme is secondary.
- **Privacy-first** — Zero tracking, no ads. API key hidden in backend `.env`. Fully functional offline for cached data.
- **Typography:** Inter (via `google_fonts`) for all text. JetBrains Mono defined in PRD but **not currently used** in codebase.
- **Brand accent:** Cyan/teal `#00BCD4` (NOT orange as in some early PRD versions).
- **Severity colours:** Critical `#FF1744`, Emergency `#FF6D00`, Warning `#FFC400`, Advisory `#00E5FF`, Info `#69F0AE`, Calm `#42A5F5`.

## Architecture & Codebase Guidelines

### 1. Directory Structure
```
lib/
├── core/
│   ├── constants/        # Enums (app_colors.dart), API/UI constants, Sri Lanka data (app_sl_constants.dart), spacing, weather codes
│   ├── di/               # get_it service locator (injection.dart)
│   ├── router/           # GoRouter with ShellRoute (app_router.dart)
│   ├── theme/            # darkTheme() + lightTheme() + colour vision overrides (app_theme.dart)
│   └── utils/            # DateTime, String formatting, WeatherAlertDeriver (threshold-based alert derivation)
├── data/
│   ├── remote/accuweather/  # AccuWeatherClient (Dio → backend proxy)
│   ├── local/hive/          # HiveService (weather_cache + settings boxes)
│   └── repositories/        # WeatherRepositoryImpl, SettingsRepositoryImpl
├── domain/
│   ├── entities/         # WeatherData, Alert, Location, TimelineEvent, CrisisPin (defined, not used)
│   └── repositories/     # Abstract WeatherRepository, SettingsRepository
├── presentation/
│   ├── blocs/weather/    # WeatherBloc + events + states (part files)
│   ├── blocs/settings/   # SettingsBloc + events + states (part files)
│   ├── screens/          # home, map, timeline, weather, weather_detail, settings, menu
│   └── widgets/          # main_scaffold, national_local_toggle, alert_banner, weather_card, forecast_card, location_search_widget, stale_data_banner
└── main.dart             # Entry point, DI init, SettingsBloc-driven theme
```

### 2. BLoC Pattern
- **WeatherBloc:** `WeatherInitial → WeatherLoading → WeatherLoaded/WeatherError`. Uses cache-first pattern: emits cached data immediately, then fetches fresh data via private `_FetchWeatherInBackground` event. Falls back to stale cache on error.
- **SettingsBloc:** Single `SettingsState` with all preference fields. Events for each setting toggle/change.
- **No AlertBloc yet** — alerts are currently derived from weather thresholds by [`WeatherAlertDeriver`](lib/core/utils/weather_alert_deriver.dart). A separate `AlertBloc` is planned (see [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md)).
- **No usecases layer** — BLoCs call repositories directly. This is intentional simplification.

### 3. UI Implementation
- **Do NOT use generic Material 3 defaults.** Use the theme from [`AppTheme.darkTheme()`/`lightTheme()`](lib/core/theme/app_theme.dart). Cards have 1px `#2A2A2A` border, 12dp radius, zero elevation on dark theme.
- **Colours:** Always reference severity colours via `SeverityLevel.color` getter. Use accent `#00BCD4` for interactive elements.
- **Many screens use inline styling** rather than theme tokens (e.g., `Colors.white.withValues(alpha: 0.5)`, `const Color(0xFF1A1A1A)`). Prefer theme tokens where available; use inline styling consistent with existing patterns where not.
- **Sri Lanka context:** Default coordinates are `LatLng(6.9271, 79.8612)` (Colombo). Map bounds, districts, cities, and alert types are in [`app_sl_constants.dart`](lib/core/constants/app_sl_constants.dart).
- **Bottom nav:** 5 tabs — Home (`/home`), Timeline (`/timeline`), Map (`/map`), Weather (`/weather`), Menu (`/menu`). Defined in [`main_scaffold.dart`](lib/presentation/widgets/main_scaffold.dart).

### 4. Data Handling & API
- **Weather data pipeline:** `AccuWeather API → Shelf Backend Proxy (localhost:8080) → AccuWeatherClient (Dio) → WeatherRepositoryImpl (cache check → fetch) → WeatherBloc → UI`
- **The backend proxy is REQUIRED** for weather data. Start it with: `cd backend && dart pub get && dart run lib/server.dart`. The backend needs an `ACCUWEATHER_API_KEY` in `backend/.env`.
- **Weather codes are AccuWeather icon codes** (1–47), NOT WMO codes. Use [`WeatherCodeMapping`](lib/core/constants/weather_codes.dart) for code→description/emoji mapping.
- **Cache aggressively** with `HiveService`. Two Hive boxes: `weather_cache` (current + hourly + daily) and `settings` (user preferences). Cache TTLs: 10 min (current), 1 hour (hourly), 3 hours (daily).
- **Legacy cache support:** [`WeatherRepositoryImpl._tryLegacyCacheDeserialize()`](lib/data/repositories/weather_repository_impl.dart:159) handles older Open-Meteo-style cache keys. Do not remove this.
- **Rain radar** uses RainViewer public API (free, no key). Fetched directly from client in [`map_screen.dart`](lib/presentation/screens/map/map_screen.dart:33), not through backend.

### 5. Sri Lanka Localization
- **25 districts** in [`SLDistrict`](lib/core/constants/app_sl_constants.dart:36) enum with `displayName`, `province`, `center` coordinates.
- **6 DMC alert types** in [`SLAlertType`](lib/core/constants/app_sl_constants.dart:94) enum: flood, landslide, cyclone, lightning, coastalWarning, tsunami.
- **12 major cities** in [`SLCityConstants.majorCities`](lib/core/constants/app_sl_constants.dart:153).
- **Monsoon detection** via [`SLMonsoon.current()`](lib/core/constants/app_sl_constants.dart:202) from date.
- **National/Local toggle:** [`NationalLocalToggle`](lib/presentation/widgets/national_local_toggle.dart) widget shared across Home, Timeline, and Weather screens. Uses "Island-wide" / "District" labels, not "National" / "Local".
- **WeatherBloc** supports `LoadWeatherForDistrict` event for district-specific weather fetching.

### 6. Files to Read Before Implementing Features
- **Product requirements + design:** [`NERV_Flutter_App_PRD.md`](NERV_Flutter_App_PRD.md) — the canonical PRD updated to match actual codebase
- **DMC alert integration plan:** [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md) — architectural plan for real alert pipeline
- **SL localization plan:** [`plans/sri_lanka_localization_plan.md`](plans/sri_lanka_localization_plan.md) — completed localization implementation plan
- **How to start:** [`How to start.md`](How to start.md) — backend + frontend startup commands

### 7. Known Issues & Gotchas
- [`weather_detail_screen.dart`](lib/presentation/screens/weather_detail/weather_detail_screen.dart) uses **hardcoded placeholder data** — needs wiring to WeatherBloc.
- `flutter_local_notifications` and `permission_handler` are in pubspec but **not wired up**.
- `drift` (SQLite) is NOT in pubspec — only Hive is used for local storage.
- `home_widget`, `firebase_messaging`, `injectable`/`injectable_generator` are NOT in pubspec — removed from early PRD plans.
- `freezed` and `json_serializable` are in dev_dependencies but entities use manual `Equatable` classes — no code generation is actually used.
- **Fonts are loaded via `google_fonts` at runtime** — first launch requires network for fonts. No bundled font assets in `assets/fonts/`.
- `assets/icons/` and `assets/images/` directories exist but contain only `.gitkeep` — no actual assets yet.
- The Menu screen in [`menu_screen.dart`](lib/presentation/screens/menu/menu_screen.dart) has hardcoded menu items (Language, Appearance, Notifications, Widget Settings) that are **non-functional** — they're display-only navigation placeholders.
- The "Weather data: Open-Meteo" footer text in [`settings_screen.dart`](lib/presentation/screens/settings/settings_screen.dart:316) is **stale/incorrect** — actual data comes from AccuWeather. The About dialog in the same file also references AccuWeather.
- `connectivity_plus` is in pubspec but connectivity checks are not implemented — the app relies on cache fallback on network error.

### 8. What NOT to Do
- Do NOT call AccuWeather API directly from the client. All AccuWeather calls must go through the backend proxy.
- Do NOT use Open-Meteo API or WMO weather codes. The app uses AccuWeather icon codes (1–47).
- Do NOT add a `usecases` layer — the architecture intentionally omits it.
- Do NOT use `drift`/SQLite — only `hive_flutter` is used for local storage.
- Do NOT add Firebase, AdMob, or any analytics/tracking SDK.
- Do NOT change the accent colour from `#00BCD4` (cyan) unless explicitly instructed.
- Do NOT remove the legacy cache deserialization fallback in WeatherRepositoryImpl.
- Do NOT use Japan-centric locations or terminology — the app is Sri Lanka-focused.
