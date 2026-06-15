# Product Requirements Document
# NERV Disaster Prevention — Flutter App

**Document Version:** 3.0
**Last Updated:** May 27, 2026
**Platform:** Flutter (iOS, Android, Web, Windows, macOS, Linux)
**Inspired By:** nerv.app/en — Gehirn Inc.
**Weather Data Provider:** WeatherAPI.com (called directly from the Flutter client)
**Target Region:** Sri Lanka (25 districts, DMC alert types)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Goals](#2-product-vision--goals)
3. [Target Users & Region](#3-target-users--region)
4. [Design System](#4-design-system)
   - 4.1 Brand Identity
   - 4.2 Colour Palette
   - 4.3 Typography
   - 4.4 Spacing & Grid
   - 4.5 Iconography
   - 4.6 Elevation & Shadows
   - 4.7 Component Library
   - 4.8 Accessibility Tokens
5. [Screen Architecture & UI Specifications](#5-screen-architecture--ui-specifications)
   - 5.1 Navigation Structure
   - 5.2 Home Screen
   - 5.3 Map Screen (Rain Radar)
   - 5.4 Timeline Screen
   - 5.5 Weather Screen
   - 5.6 Menu Screen
   - 5.7 Settings Screen
   - 5.8 Weather Detail Screen
6. [Feature Specifications](#6-feature-specifications)
7. [Backend Architecture](#7-backend-architecture)
8. [Weather Data Pipeline](#8-weather-data-pipeline)
9. [Flutter Architecture](#9-flutter-architecture)
10. [Flutter Package Dependencies](#10-flutter-package-dependencies)
11. [Sri Lanka Localization](#11-sri-lanka-localization)
12. [Planned Features & Roadmap](#12-planned-features--roadmap)
13. [Privacy & Security Requirements](#13-privacy--security-requirements)
14. [Non-Functional Requirements](#14-non-functional-requirements)
15. [Accessibility Requirements](#15-accessibility-requirements)
16. [Open Questions & Risks](#16-open-questions--risks)

---

## 1. Executive Summary

This PRD defines the complete requirements for a Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. The app delivers real-time weather data, derived emergency-level alerts, rain radar mapping, and a timeline of weather events in a tactical, high-contrast dark UI.

**Weather data** is sourced from **WeatherAPI.com** via a single `/forecast.json` request made directly from the Flutter client (no backend proxy). The app is localized for **Sri Lanka** with 25 districts, DMC-style disaster alert categories, and monsoon awareness.

The app is designed to function as both an everyday weather companion and an emergency information hub, with an uncompromisingly clean aesthetic and a privacy-first data model.

---

## 2. Product Vision & Goals

### Vision
> "Before the shake. Before the flood. Before the danger — you already know."

### Goals

| # | Goal | KPI |
|---|------|-----|
| G1 | Deliver weather & derived alerts from WeatherAPI.com data | Alert derivation latency < 5s |
| G2 | Zero advertisements, zero tracking | No ad SDK in the app bundle |
| G3 | Fully functional offline for cached data | Core screens load with stale data when offline |
| G4 | Accessibility-first design | WCAG 2.1 AA compliance |
| G5 | Minimal battery footprint | Efficient caching, minimal background work |
| G6 | Sri Lanka-focused with district-level weather | 25 districts, 12 major cities |

---

## 3. Target Users & Region

### Region: Sri Lanka
The app is localized for Sri Lanka with:
- **25 districts** across 9 provinces (Western, Central, Southern, Northern, Eastern, North Western, North Central, Uva, Sabaragamuwa)
- **12 major cities** for weather data
- **6 DMC-aligned disaster alert types**: Flood, Landslide, Cyclone, Lightning, Coastal Warning, Tsunami
- **Monsoon awareness**: SW Monsoon (May–Sep), NE Monsoon (Dec–Feb), two inter-monsoon periods

### Persona 1 — "The Daily Commuter" (Primary)
- Age: 25–45, urban resident
- Need: Quick glance at rain radar and temperature before leaving home
- Pain point: Too many weather apps cluttered with ads and irrelevant content
- Uses: Home screen with map + conditions, rain radar tab

### Persona 2 — "The Emergency-Aware Resident" (Primary)
- Age: 30–60, lives in disaster-prone area (flood/landslide zones)
- Need: Immediate awareness of flood, landslide, and cyclone risks
- Pain point: Delayed or missed alerts from standard sources
- Uses: Derived alerts on Home screen, Timeline screen

### Persona 3 — "The Accessibility User" (Secondary)
- Age: Any, has colour vision deficiency or low vision
- Need: App that doesn't rely solely on colour for critical info
- Uses: High-contrast theme, screen reader layout, adjustable text, colour vision modes

---

## 4. Design System

### 4.1 Brand Identity

The visual language is inspired by NERV's tactical operations interface — dark, structured, data-dense, and built for rapid information parsing.

**Design Principles:**
1. **Clarity over decoration** — Every pixel serves information
2. **Urgency hierarchy** — Colour and size signal severity, not aesthetics
3. **Night-mode first** — Dark theme is canonical; pure black `#000000` background
4. **Motion is informative** — Animations signal real-time data changes, not flourishes
5. **No noise** — No ads, no banners, no promotional elements ever

### 4.2 Colour Palette

#### Base (Dark Theme — Primary)

| Token | Hex | Usage |
|-------|-----|-------|
| `color-bg-primary` | `#000000` | Main background, scaffold |
| `color-bg-surface` | `#1A1A1A` | Cards, panels, bottom sheets |
| `color-bg-elevated` | `#252525` | Elevated cards, modal backgrounds |
| `color-border-default` | `#2A2A2A` | Card borders, dividers |
| `color-border-subtle` | `#1E1E1E` | Subtle separators |

#### Brand Accent

| Token | Hex | Usage |
|-------|-----|-------|
| `color-accent-primary` | `#00BCD4` | Primary CTA, active states, brand accent (cyan/teal) |
| `color-accent-secondary` | `#00E5FF` | Secondary highlights, hover states |

#### Severity Scale (Critical to Informational)

| Token | Hex | Label | Used For |
|-------|-----|-------|----------|
| `color-severity-critical` | `#FF1744` | CRITICAL | Tsunami, Extreme Cyclone |
| `color-severity-emergency` | `#FF6D00` | EMERGENCY | Flood Emergency, Major Landslide |
| `color-severity-warning` | `#FFC400` | WARNING | Flood Watch, Strong Wind, Thunderstorm |
| `color-severity-advisory` | `#00E5FF` | ADVISORY | Weather Advisory, UV Hazard, Heavy Rain |
| `color-severity-info` | `#69F0AE` | INFO | Routine updates, Forecast |
| `color-severity-calm` | `#42A5F5` | CALM | Clear sky, no alerts, All Clear |

#### Text Colours

| Token | Hex | Usage |
|-------|-----|-------|
| `color-text-primary` | `#F0F2F8` | Primary body text, headings |
| `color-text-secondary` | `#8B95B0` | Secondary labels, captions |
| `color-text-tertiary` | `#5A5A5A` | Disabled text, placeholder |

#### Light Theme Overrides

| Token | Hex | Usage |
|-------|-----|-------|
| `color-bg-primary` | `#F4F6FA` | Main background |
| `color-bg-surface` | `#FFFFFF` | Cards, panels |
| `color-border-default` | `#D0D5E8` | Card borders |
| `color-text-primary` | `#0F1120` | Body text |
| `color-text-secondary` | `#5A6280` | Labels |

#### Colour Vision Accessible Overrides

Implemented in [`AppTheme._getAdjustedSeverityColors()`](lib/core/theme/app_theme.dart:315).

**Protanopia/Deuteranopia (Red–Green):**
- Replace `color-severity-critical` with `#0072B2` (Blue)
- Replace `color-severity-info` with `#E69F00` (Orange)

**Tritanopia (Blue–Yellow):**
- Replace `color-severity-advisory` with `#CC79A7` (Pink)
- Replace `color-severity-calm` with `#009E73` (Teal)

### 4.3 Typography

**Primary Typeface:** `Inter` (via `google_fonts` package, loaded at runtime)

There are no bundled font assets. All fonts are served by the `google_fonts` package. The monospace typeface (`JetBrains Mono`) is **not currently used** in the codebase.

#### Type Scale

Implemented in [`AppTheme._buildTextTheme()`](lib/core/theme/app_theme.dart:203) using Material 3 `TextTheme` with `google_fonts`:

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `displayLarge` | 32sp | Bold (700) | 40/32 | Alert headlines, major readouts |
| `displayMedium` | 28sp | Bold (700) | 36/28 | Large temp displays |
| `displaySmall` | 24sp | Bold (700) | 32/24 | - |
| `headlineLarge` | 24sp | SemiBold (600) | 32/24 | Screen titles |
| `headlineMedium` | 20sp | SemiBold (600) | 28/20 | Section headers |
| `headlineSmall` | 17sp | SemiBold (600) | 24/17 | Card sub-headers |
| `titleLarge` | 16sp | SemiBold (600) | 24/16 | - |
| `titleMedium` | 14sp | SemiBold (600) | 20/14 | - |
| `titleSmall` | 12sp | SemiBold (600) | 18/12 | - |
| `bodyLarge` | 16sp | User-configurable | 24/16 | Primary body |
| `bodyMedium` | 14sp | User-configurable | 20/14 | Secondary body |
| `bodySmall` | 12sp | User-configurable | 18/12 | Captions, metadata |
| `labelLarge` | 14sp | Medium (500) | 20/14 | Button labels |
| `labelMedium` | 12sp | Medium (500) | 16/12 | - |
| `labelSmall` | 11sp | Medium (500) | 16/11 | Tags, chips, badge text |

#### User-Adjustable Settings

| Setting | Enum | Values |
|---------|------|--------|
| Text Size | `TextSizeScale` | xSmall (0.75×), small (0.875×), normal (1.0×), large (1.125×), xLarge (1.25×), xxLarge (1.5×) |
| Font Weight | `FontWeightScale` | normal (w400), medium (w500), bold (w700) |

Defined in [`lib/core/constants/app_colors.dart`](lib/core/constants/app_colors.dart:80).

### 4.4 Spacing & Grid

**Base unit:** 4dp

| Token | Value | Usage |
|-------|-------|-------|
| `space1` | 4dp | Micro gaps (icon-to-label) |
| `space2` | 8dp | Component internal padding (tight) |
| `space3` | 12dp | Component internal padding (standard) |
| `space4` | 16dp | Card padding, section gaps |
| `space5` | 20dp | List item vertical padding |
| `space6` | 24dp | Screen horizontal margin |
| `space8` | 32dp | Section vertical spacing |
| `space10` | 40dp | Large section gaps |
| `space12` | 48dp | Bottom nav clearance |

**Border Radius:**

| Token | Value | Usage |
|-------|-------|-------|
| `radiusXs` | 4dp | Tags, chips, small badges |
| `radiusSm` | 8dp | Buttons, small cards |
| `radiusMd` | 12dp | Standard cards, panels |
| `radiusLg` | 16dp | Bottom sheets, modal cards |
| `radiusXl` | 24dp | Hero cards, large panels |
| `radiusFull` | 999dp | Pills, circular elements |

**Screen Layout Constants (from [`app_constants.dart`](lib/core/constants/app_constants.dart:13)):**
```
Content max-width:  600dp (tablet)
Bottom nav height:  64dp + safe area inset
Top bar height:     56dp + status bar inset
Min touch target:   48dp
```

### 4.5 Iconography

**Icon Library:** `Material Symbols` (built-in Material Design icons)

| Icon Purpose | Material Icon |
|-------------|---------------|
| Flood | `Icons.water` |
| Landslide | `Icons.terrain` |
| Cyclone | `Icons.cyclone` |
| Lightning | `Icons.bolt` |
| Coastal Warning | `Icons.beach_access` |
| Tsunami | `Icons.waves` |
| Map / Layers | `Icons.layers` |
| My Location | `Icons.my_location` |
| Home | `Icons.home` / `Icons.home_outlined` |
| Timeline | `Icons.fact_check` / `Icons.fact_check_outlined` |
| Map Tab | `Icons.cloud` / `Icons.cloud_outlined` |
| Weather Tab | `Icons.wb_sunny` / `Icons.wb_sunny_outlined` |
| Menu | `Icons.menu` |

### 4.6 Elevation & Shadows

Dark theme uses **border-based elevation** rather than shadow-based (shadows are invisible on dark backgrounds). Light theme uses standard Material elevation shadows.

Dark theme card: zero elevation, 1px `#2A2A2A` border, 12dp radius.
Light theme card: elevation 2, 6% opacity shadow, 1px `#D0D5E8` border.

### 4.7 Component Library

#### A. Alert Card (Home Screen)

Built inline in [`home_screen.dart`](lib/presentation/screens/home/home_screen.dart:432) as `_buildAlertInfoCard()`:
- 44dp circle icon with severity colour at 15% opacity
- Title in 18sp white bold
- Severity chip with colour-matched background
- Timestamp, description text (max 3 lines)
- Chevron right icon
- Full card is tappable

#### B. Current Conditions Chip (Home Screen)

Built inline in [`home_screen.dart`](lib/presentation/screens/home/home_screen.dart:337):
- 36sp temperature with weather emoji
- Weather description
- Feels like, humidity, wind detail row
- `#1A1A1A` background with subtle border

#### C. National/Local Toggle

Reusable widget at [`national_local_toggle.dart`](lib/presentation/widgets/national_local_toggle.dart):
- Pill toggle: "Island-wide" / "[District Name]"
- Animated container with 200ms transition
- `+` button opens district picker bottom sheet
- 25 Sri Lankan districts, alphabetically sorted, grouped by province

#### D. Bottom Navigation Bar

Implemented in [`main_scaffold.dart`](lib/presentation/widgets/main_scaffold.dart):
- 5 tabs: Home, Timeline, Map, Weather, Menu
- Height: 64dp + bottom safe area
- Active: `#00BCD4` (cyan) icon + label
- Inactive: `#5A5A5A` (tertiary text)
- Background matches scaffold background

#### E. Stale Data Banner

At [`stale_data_banner.dart`](lib/presentation/widgets/stale_data_banner.dart):
- Shows "Last updated: X ago" with refresh icon
- Accent-coloured background at 10% opacity

#### F. Timeline Event Row

Built inline in [`timeline_screen.dart`](lib/presentation/screens/timeline/timeline_screen.dart:195):
- Left time column (52dp wide)
- Timeline line + 36dp circle dot with severity colour
- Event type label + title
- "LIFTED" badge for resolved events
- Date separator pill between groups

### 4.8 Accessibility Tokens

```dart
// From app_constants.dart
static const double minTouchTarget = 48.0;
static const double focusRingWidth = 2.0;
static const Color focusRingColor = Color(0xFF00E5FF);
static const double minContrastRatio = 4.5;
```

Three colour vision modes selectable in Settings: Normal, Protanopia/Deuteranopia, Tritanopia.

---

## 5. Screen Architecture & UI Specifications

### 5.1 Navigation Structure

```
App Root (MaterialApp.router with GoRouter)
├── ShellRoute (MainScaffold — Bottom Navigation Bar)
│   ├── [Tab 1] /home      — HomeScreen
│   ├── [Tab 2] /timeline  — TimelineScreen
│   ├── [Tab 3] /map       — MapScreen (Rain Radar)
│   ├── [Tab 4] /weather   — WeatherScreen
│   └── [Tab 5] /menu      — MenuScreen
│
├── Push Route
│   └── /weather-detail    — WeatherDetailScreen
│
└── Modal Routes (bottom sheets)
    └── District picker (from NationalLocalToggle)
```

**Router implementation:** [`lib/core/router/app_router.dart`](lib/core/router/app_router.dart)

### 5.2 Home Screen

**File:** [`lib/presentation/screens/home/home_screen.dart`](lib/presentation/screens/home/home_screen.dart)

**Purpose:** Primary dashboard with interactive map, current conditions, and derived alerts.

**Layout (top to bottom):**
```
┌────────────────────────────────────────────┐
│  [ Island-wide ] | [ District ▼ ]    [+]   │  ← NationalLocalToggle
├────────────────────────────────────────────┤
│  Join as a Supporter          Learn More › │  ← Supporter banner
├────────────────────────────────────────────┤
│  ╔══════════════════════════════════════╗  │
│  ║        Interactive Map              ║  │  ← 55% of body
│  ║    (flutter_map + CartoDB dark)     ║  │     Island-wide view
│  ║         with GPS marker             ║  │     Tap district → zooms
│  ╚══════════════════════════════════════╝  │
│     ─── Rainbow gradient separator ───     │
├────────────────────────────────────────────┤
│  Island-wide                         45%   │
│  ⛅ 28.4°C  Partly Sunny            Feels  │  ← Current conditions chip
│                           Hum 72% Wind 12  │
│                                            │
│  ⚠ Colombo — Flood Warning    [WARNING]   │  ← Derived alerts
│     Heavy rainfall (15.2 mm/h)...      ›   │     sorted by severity
│  ⚡ Colombo — Lightning Alert  [WARNING]   │
│  ...                                       │
└────────────────────────────────────────────┘
│  🏠 Home │ 📋 Timeline │ ☁ Map │ ☀ Weather │ ☰ │
└────────────────────────────────────────────┘
```

**Behaviour:**
- Weather data fetched from WeatherAPI.com (called directly from the client)
- Alerts derived from weather thresholds by [`WeatherAlertDeriver`](lib/core/utils/weather_alert_deriver.dart)
- Map centers on Sri Lanka (7.87°N, 80.77°E) at zoom 7.2
- District selection zooms map to district center at zoom 10.0
- Cached data shown immediately; fresh data fetched in background
- Stale data banner appears when showing cached data

### 5.3 Map Screen (Rain Radar)

**File:** [`lib/presentation/screens/map/map_screen.dart`](lib/presentation/screens/map/map_screen.dart)

**Purpose:** Full-screen rain radar with time scrubber.

**Layout:**
```
┌────────────────────────────────────────────┐
│       Rain Radar — Sri Lanka               │  ← Title
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ← Color legend│
│  1    5   10   20   30  50  80  (mm/h)     │
├────────────────────────────────────────────┤
│  ⛅ 28°C                                   │  ← Weather chip (top-left)
│  Colombo                                   │
│                                    ┌────┐  │
│        [Interactive Map]           │ ⊙  │  │  ← My Location button
│    (CartoDB dark + RainViewer      └────┘  │
│     precipitation overlay)                 │
│                                            │
├────────────────────────────────────────────┤
│  Now  14:30                     [Layers]   │  ← Time scrubber
│  | | | | | | | | | | | | |                │  ← Time ticks (5-min steps)
└────────────────────────────────────────────┘
```

**Data Sources:**
- **Map tiles:** CartoDB Dark Matter (free, no API key)
- **Rain overlay:** RainViewer API (free, no API key) — fetches `weather-maps.json`, uses last `past` radar frame
- **GPS location:** From WeatherBloc state

### 5.4 Timeline Screen

**File:** [`lib/presentation/screens/timeline/timeline_screen.dart`](lib/presentation/screens/timeline/timeline_screen.dart)

**Purpose:** Chronological feed of derived weather events.

**Layout:**
```
┌────────────────────────────────────────────┐
│  [ Island-wide ] | [ District ▼ ]    [+]   │
├────────────────────────────────────────────┤
│              ┌──────────┐                  │
│              │  Today   │                  │  ← Date separator pill
│              └──────────┘                  │
│                                            │
│  14:32  ●  Flood Warning                   │
│   │        Colombo — Flood Warning         │
│   │        Heavy rainfall detected...       │
│   │                                        │
│  14:32  ●  Lightning Alert                 │
│   │        Colombo — Lightning Alert       │
│   │        Thunderstorm activity...         │
│   │                                        │
│              ┌──────────────┐              │
│              │  Tomorrow    │              │
│              └──────────────┘              │
│                                            │
│  00:00  ●  Heavy Rain Forecast             │
│            Colombo — Heavy Rain...         │
└────────────────────────────────────────────┘
```

**Behaviour:**
- Events derived from [`WeatherAlertDeriver.deriveTimelineEvents()`](lib/core/utils/weather_alert_deriver.dart:213)
- Grouped by date (Today, Tomorrow, [Weekday] M/D)
- Timeline line connects events within each date group
- Severity-coloured circle dots
- "LIFTED" badge for resolved events
- District toggle filters events

### 5.5 Weather Screen

**File:** [`lib/presentation/screens/weather/weather_screen.dart`](lib/presentation/screens/weather/weather_screen.dart)

**Purpose:** Detailed weather view with draggable sheet over a map.

**Layout:**
```
┌────────────────────────────────────────────┐
│  [ Island-wide ] | [ District ▼ ]    [+]   │
│                                            │
│        [Map Background — CartoDB dark]     │
│                                            │
│  ┌────────────────────────────────────┐    │
│  │  ━━━━━━  ← drag handle             │    │
│  │                                    │    │
│  │  Colombo Weather                   │    │
│  │  2026/05/27 (Tue)                  │    │
│  │  ─────────────────────────────     │    │
│  │                                    │    │
│  │  ⛅  28.4°C                        │    │
│  │      Partly Sunny                  │    │
│  │                                    │    │
│  │  Feels Like │ Humidity            │    │
│  │  32.1°C     │ 72%                 │    │
│  │  Wind       │ Pressure            │    │
│  │  12.5 km/h  │ 1013 hPa            │    │
│  │  UV Index   │ Cloud Cover         │    │
│  │  8.2        │ 45%                 │    │
│  │                                    │    │
│  │  Hourly Forecast        12 hours   │    │
│  │  [14:00] [15:00] [16:00] ...      │    │
│  │  ─────────────────────────────     │    │
│  │                                    │    │
│  │  5-Day Forecast                    │    │
│  │  Today    ⛅  24° ━━━━ 35°         │    │
│  │  Tomorrow ⛅  23° ━━━━ 30°         │    │
│  │  Wed      🌧  22° ━━━━ 27°         │    │
│  │  ...                               │    │
│  └────────────────────────────────────┘    │
└────────────────────────────────────────────┘
```

**Behaviour:**
- `DraggableScrollableSheet` (0.45 initial, 0.15 min, 0.85 max)
- Map background re-centers on district selection
- Current conditions: 56sp temperature, 2×2 detail grid
- Hourly forecast: horizontal scroll strip, 72dp-wide chips
- 5-day forecast: rows with day label, emoji, precipitation %, temp range bar
- Temp range bar: cyan (#00BCD4) to orange (#FF6B00) gradient

### 5.6 Menu Screen

**File:** [`lib/presentation/screens/menu/menu_screen.dart`](lib/presentation/screens/menu/menu_screen.dart)

**Purpose:** Combined menu with saved regions, supporters club, settings shortcuts, and about section.

**Sections:**
1. Title "Menu" + rainbow gradient stripe
2. **Saved Regions** — Shows "0 / 3" counter, "Add" button (cyan `#00BCD4`)
3. **Supporters' Club Membership Card** — Hero card with NERV branding, dark red overlay
4. **Settings** — Menu items: Language (English), Appearance, Notifications, Widget Settings
5. **About this app** — Version (1.0.0), News, Remarks, Terms of Service, Privacy Policy, License Information, Contact Us
6. **Footer** — "ゲヒルン危機管理局" + "In Collaboration with @UN_NERV"

### 5.7 Settings Screen

**File:** [`lib/presentation/screens/settings/settings_screen.dart`](lib/presentation/screens/settings/settings_screen.dart)

**Purpose:** Accessibility settings and notification preferences.

**Sections:**
1. **Header** — "Settings" title
2. **Accessibility** — Dark Mode toggle, Text Size selector (6 options), Font Weight selector (3 options), Colour Vision selector (3 modes), Contrast selector (3 levels)
3. **Notifications** — 7 toggles: Critical Alerts, Flood Alerts, Landslide Alerts, Cyclone Advisories, Lightning Alerts, Coastal Warnings, Tsunami Bulletins
4. **About** — About NERV dialog, Privacy Policy, Terms of Service
5. **Footer** — "NERV — Sri Lanka", Version 1.0.0, "Weather data: Open-Meteo" (legacy text), "Alerts: DMC Sri Lanka"

All selectors use modal bottom sheets with checkmark on selected item.

### 5.8 Weather Detail Screen

**File:** [`lib/presentation/screens/weather_detail/weather_detail_screen.dart`](lib/presentation/screens/weather_detail/weather_detail_screen.dart)

**Purpose:** Full expanded view (currently uses hardcoded/placeholder data).

**Sections:**
1. Current conditions hero (gradient background, 72sp emoji, temperature, condition items)
2. Hourly forecast chart (fl_chart LineChart, 7 data points)
3. 7-Day forecast list (hardcoded)
4. Sunrise & Sunset card
5. Wind details card (Direction, Speed, Gusts)

---

## 6. Feature Specifications

### F-01 Weather Alert Derivation

Alerts are derived from live WeatherAPI.com data by [`WeatherAlertDeriver`](lib/core/utils/weather_alert_deriver.dart).

**Thresholds:**

| Alert Type | Condition | Severity |
|------------|-----------|----------|
| Flood Emergency | Precipitation ≥ 15 mm/h | EMERGENCY |
| Flood Watch | Precipitation ≥ 5 mm/h | WARNING |
| Heavy Rain Advisory | Precipitation ≥ 1 mm/h AND probability ≥ 50% | ADVISORY |
| Cyclone Advisory | Wind speed ≥ 50 km/h | EMERGENCY |
| Strong Wind Alert | Wind speed ≥ 30 km/h | WARNING |
| Lightning Alert | Thunderstorm weather codes (14–18, 40–44) | WARNING |
| Coastal Warning | Wind ≥ 30 km/h AND precipitation probability ≥ 40% | WARNING |
| UV Hazard Advisory | UV Index ≥ 8.0 | ADVISORY |
| Landslide Watch | Cloud cover ≥ 90% AND precipitation ≥ 1 mm/h | WARNING |
| All Clear | No hazardous conditions | CALM |

**Features:**
- Alerts sorted by severity (most severe first)
- Per-district alert context when a district is selected
- Timeline events derived from both current conditions and 5-day daily forecast
- Daily forecast alerts include "Tomorrow" / "Day N" labels

### F-02 Rain Radar

| Field | Spec |
|-------|------|
| Data | RainViewer public API (`api.rainviewer.com/public/weather-maps.json`) |
| Overlay | Tile layer from `tilecache.rainviewer.com` |
| Refresh | On screen init |
| UI | Full-screen map with colour legend (blue→cyan→yellow→orange→red→magenta), time scrubber with 5-min ticks |
| File | [`map_screen.dart`](lib/presentation/screens/map/map_screen.dart) |

### F-03 Weather Forecasts

| Field | Spec |
|-------|------|
| Current | Temperature, apparent temperature, weather icon, wind speed/direction, humidity, precipitation, pressure, cloud cover, UV index |
| Hourly | 12 hours from WeatherAPI.com (temperature, precip probability, precip, wind, gusts, weather code, UV, visibility, humidity) |
| Daily | 5 days from WeatherAPI.com (weather code, temp max/min, precip sum, precip probability max, wind max, gusts max, sunrise, sunset, UV max) |
| Refresh | Cache TTL: 10 min (current), 1 hour (hourly), 3 hours (daily) |

### F-04 Weather Code Mapping

Uses **WeatherAPI.com condition codes** (1000–1282), not WMO codes. Defined in [`weather_codes.dart`](lib/core/constants/weather_codes.dart).

### F-05 Timeline

| Field | Spec |
|-------|------|
| Duration | Events derived from current + 5-day forecast |
| Storage | In-memory (derived on-the-fly from WeatherBloc state) |
| Event Types | Flood, Landslide, Cyclone, Lightning, Coastal Warning, Tsunami |
| Grouping | Date sections (Today, Tomorrow, [Weekday] M/D) |
| File | [`timeline_screen.dart`](lib/presentation/screens/timeline/timeline_screen.dart) |

---

## 7. Client Architecture

The app calls **WeatherAPI.com** directly from the Flutter client. The API key is loaded from a gitignored `.env` file via `flutter_dotenv` and exposed through `ApiConstants` getters. No backend server is involved in the weather pipeline.

**File:** [`lib/data/remote/weatherapi/weather_api_client.dart`](lib/data/remote/weatherapi/weather_api_client.dart)

### Architecture

```
Flutter App ──→ WeatherAPI.com (/forecast.json)
                     │
                     └── .env file (WEATHERAPI_KEY, MAPTILER_API_KEY, OWM_API_KEY)
```

### Endpoints (WeatherAPI.com)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/forecast.json` | Current + 12h hourly + 5-day daily in a single request |

### Dependencies (client only)

```yaml
# pubspec.yaml
flutter_dotenv: ^5.1.0   # loads .env at startup
dio: ^5.7.0              # HTTP client used by WeatherApiClient
dio_cache_interceptor: ^3.5.0  # in-memory HTTP cache
hive_flutter: ^1.1.0     # on-disk cache for weather + settings
```

### How to Start

```bash
flutter pub get
flutter run
```

The app reads `WEATHERAPI_KEY`, `MAPTILER_API_KEY`, and `OWM_API_KEY` from a gitignored `.env` at the project root.

See [`How to start.md`](How to start.md) for full instructions.

---

## 8. Weather Data Pipeline

### Data Flow

```
WeatherAPI.com (/forecast.json)
     │  returns: current + hourly + daily in one payload
     │  codes: WeatherAPI.com condition codes (1000–1282)
     ▼
WeatherApiClient (Dio HTTP client, direct from Flutter)
     │
     ▼
WeatherRepositoryImpl
     │  ├─ Cache check (Hive, 10-min TTL)
     │  ├─ Fetch + parse + cache on miss
     │  └─ Legacy cache deserialization fallback
     ▼
WeatherBloc
     │  ├─ WeatherInitial → LoadWeather / LoadWeather(useGps:true)
     │  ├─ WeatherLoading → show spinner
     │  ├─ WeatherLoaded  → current + hourly + daily + location
     │  └─ WeatherError   → show error with stale cache
     ▼
HomeScreen / WeatherScreen / MapScreen / TimelineScreen
     │
     ▼
WeatherAlertDeriver (threshold-based alert + timeline event derivation)
```

### Caching Strategy

```dart
// From app_constants.dart
static const Duration currentWeatherCacheTtl = Duration(minutes: 10);
static const Duration hourlyForecastCacheTtl = Duration(hours: 1);
static const Duration dailyForecastCacheTtl = Duration(hours: 3);
```

**Cache Implementation:** `Hive` via [`HiveService`](lib/data/local/hive/hive_service.dart).

Two Hive boxes:
- `weather_cache` — Current + hourly + daily weather data + timestamp + cached location
- `settings` — User preferences (dark mode, text size, colour vision, contrast, saved locations)

The repository includes backward-compatible legacy cache deserialization (`_tryLegacyCacheDeserialize`) for older cache formats that used Open-Meteo-style key names.

---

## 9. Flutter Architecture

### 9.1 Architecture Pattern: Clean Architecture + BLoC (Simplified)

The codebase follows a simplified Clean Architecture with BLoC state management. There is **no `usecases` layer** — BLoCs call repositories directly.

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # SeverityLevel, ColourVisionMode, ContrastMode, TextSizeScale, FontWeightScale enums
│   │   ├── app_constants.dart     # ApiConstants, AppConstants
│   │   ├── app_sl_constants.dart  # Sri Lanka: 25 districts, 6 alert types, 12 cities, map bounds, monsoons
│   │   ├── app_spacing.dart       # Spacing and border radius tokens
│   │   ├── constants.dart         # Barrel export
│   │   └── weather_codes.dart     # WeatherAPI.com condition code (1000–1282) → description/emoji mapping
│   ├── di/
│   │   ├── di.dart                # Barrel export
│   │   └── injection.dart         # get_it service locator setup
│   ├── router/
│   │   ├── app_router.dart        # GoRouter with ShellRoute for 5 tabs + push route
│   │   └── router.dart            # Barrel export
│   ├── theme/
│   │   ├── app_theme.dart         # darkTheme() + lightTheme() + colour vision overrides
│   │   └── theme.dart             # Barrel export
│   └── utils/
│       ├── date_time_utils.dart   # DateTime formatting helpers
│       ├── string_utils.dart      # Temperature, wind, precipitation formatting
│       ├── utils.dart             # Barrel export
│       └── weather_alert_deriver.dart  # Threshold-based alert + timeline event derivation
│
├── data/
│   ├── local/
│   │   └── hive/
│   │       └── hive_service.dart  # Hive box management (weather_cache, settings)
│   ├── remote/
│   │   ├── weatherapi/
│   │   │   └── weather_api_client.dart  # Dio client for WeatherAPI.com /forecast.json
│   │   └── maptiler/
│   │       └── maptiler_geocoding_client.dart  # Forward + reverse geocoding
│   └── repositories/
│       ├── weather_repository_impl.dart  # WeatherRepository implementation with caching
│       └── settings_repository_impl.dart # SettingsRepository implementation with Hive
│
├── domain/
│   ├── entities/
│   │   ├── weather_data.dart      # WeatherData, CurrentWeather, HourlyWeather, DailyWeather
│   │   ├── alert.dart             # Alert entity
│   │   ├── location.dart          # Location entity with district field
│   │   ├── timeline_event.dart    # TimelineEvent entity
│   │   ├── crisis_pin.dart        # CrisisPin entity + CrisisPinType enum (defined, not yet used)
│   │   └── entities.dart          # Barrel export
│   └── repositories/
│       ├── weather_repository.dart    # Abstract WeatherRepository
│       ├── settings_repository.dart   # Abstract SettingsRepository
│       └── repositories.dart          # Barrel export
│
├── presentation/
│   ├── blocs/
│   │   ├── weather/
│   │   │   └── weather_bloc.dart  # WeatherBloc + WeatherEvent + WeatherState (part files)
│   │   └── settings/
│   │       └── settings_bloc.dart  # SettingsBloc + SettingsEvent + SettingsState (part files)
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart   # Map + conditions + derived alerts
│   │   ├── map/
│   │   │   └── map_screen.dart    # Rain radar with RainViewer overlay
│   │   ├── timeline/
│   │   │   └── timeline_screen.dart  # Chronological event feed
│   │   ├── weather/
│   │   │   └── weather_screen.dart   # Draggable sheet + weather details
│   │   ├── weather_detail/
│   │   │   └── weather_detail_screen.dart  # Full weather detail (placeholder data)
│   │   ├── settings/
│   │   │   └── settings_screen.dart  # Accessibility + notifications
│   │   └── menu/
│   │       └── menu_screen.dart   # Combined menu with supporters club + about
│   └── widgets/
│       ├── alert_banner.dart      # Reusable AlertBanner widget
│       ├── forecast_card.dart     # Daily forecast card with temp bars
│       ├── location_search_widget.dart  # Search bottom sheet with debounce + GPS option
│       ├── main_scaffold.dart     # ShellRoute scaffold with bottom NavigationBar
│       ├── national_local_toggle.dart  # Island-wide / District toggle + picker
│       ├── stale_data_banner.dart # Cache staleness indicator
│       ├── weather_card.dart      # Weather info card
│       └── widgets.dart           # Barrel export
│
└── main.dart                      # App entry point, DI init, theme setup
```

### 9.2 State Management

| Layer | Tool |
|-------|------|
| UI State | `flutter_bloc` (WeatherBloc, SettingsBloc) |
| Dependency Injection | `get_it` (manual registration) |
| Persistent Settings | `hive_flutter` (HiveService) |
| Weather Cache | `hive_flutter` (HiveService) |
| Navigation | `go_router` (ShellRoute for tabs, push route for detail) |

### 9.3 BLoC States — WeatherBloc

```
WeatherInitial
WeatherLoading
WeatherRefreshing (weatherData, location, isStaleCache, selectedDistrict)
WeatherLoaded (weatherData, location, isStaleCache, searchResults, isSearching, selectedDistrict)
WeatherError (message, cachedData?)
```

**Events:** `LoadWeather`, `LoadWeatherForDistrict`, `RefreshWeather`, `SearchLocations`, `SelectLocation`, `_FetchWeatherInBackground` (private)

The BLoC uses a pattern where cached data is emitted immediately (`WeatherLoaded` with `isStaleCache: true`), then a `_FetchWeatherInBackground` event is added to fetch fresh data. On failure, it falls back to showing the stale cache.

### 9.4 BLoC States — SettingsBloc

Single `SettingsState` with: `isDarkMode`, `colourVisionMode`, `contrastMode`, `textSizeScale`, `fontWeightScale`, `isLoaded`.

**Events:** `LoadSettings`, `ToggleDarkMode`, `SetColourVisionMode`, `SetContrastMode`, `SetTextSizeScale`, `SetFontWeightScale`.

---

## 10. Flutter Package Dependencies

```yaml
# From pubspec.yaml (actual current versions)
environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.8

  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.5
  get_it: ^9.2.1

  # Navigation
  go_router: ^17.2.2

  # Networking
  dio: ^5.7.0
  dio_cache_interceptor: ^3.5.0
  dio_cache_interceptor_hive_store: ^4.0.0
  connectivity_plus: ^7.1.1

  # Local Storage
  hive_flutter: ^1.1.0

  # Maps
  flutter_map: ^8.3.0
  latlong2: ^0.9.1

  # Location
  geolocator: ^14.0.2
  geocoding: ^4.0.0

  # Notifications
  flutter_local_notifications: ^21.0.0

  # UI & Design
  google_fonts: ^8.0.2
  flutter_svg: ^2.0.16
  shimmer: ^3.0.0
  fl_chart: ^1.2.0
  cached_network_image: ^3.4.1

  # Permissions
  permission_handler: ^12.0.1

  # Internationalization
  intl: ^0.20.2
  timeago: ^3.7.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  rxdart: ^0.28.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  freezed: ^3.2.5
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

**Assets directory:** `assets/icons/` and `assets/images/` exist but currently contain only `.gitkeep` files. No bundled font assets — fonts are loaded via `google_fonts` at runtime.

---

## 11. Sri Lanka Localization

The app is fully localized for Sri Lanka. Core data defined in [`app_sl_constants.dart`](lib/core/constants/app_sl_constants.dart).

### 25 Districts

Enumerated in `SLDistrict` with display name, province, and center coordinates.

### 9 Provinces
Western, Central, Southern, Northern, Eastern, North Western, North Central, Uva, Sabaragamuwa.

### 6 DMC-Aligned Alert Types
`SLAlertType`: flood, landslide, cyclone, lightning, coastalWarning, tsunami.

### 12 Major Cities
Colombo, Kandy, Galle, Jaffna, Batticaloa, Trincomalee, Anuradhapura, Ratnapura, Badulla, Kurunegala, Matara, Hambantota.

### Map Bounds
- Center: LatLng(7.8731, 80.7718) — near Dambulla
- Initial zoom: 7.2
- Min zoom: 6.0, Max zoom: 18.0
- SW bound: LatLng(5.9167, 79.5333)
- NE bound: LatLng(9.8167, 81.8167)

### Monsoon Awareness
`SLMonsoon` enum detects current monsoon season from date:
- SW Monsoon (May–September)
- NE Monsoon (December–February)
- 1st Inter-Monsoon (March–April)
- 2nd Inter-Monsoon (October–November)

### National/Local Toggle
The [`NationalLocalToggle`](lib/presentation/widgets/national_local_toggle.dart) widget provides Island-wide vs. District switching across Home, Timeline, and Weather screens.

---

## 12. Planned Features & Roadmap

### Completed (v1.0)
- [x] Design system (dark/light themes, typography, spacing)
- [x] Weather data pipeline (WeatherAPI.com /forecast.json, no backend)
- [x] Weather data pipeline (current + hourly + daily)
- [x] Home screen (map + conditions + derived alerts)
- [x] Weather screen (draggable sheet + detailed weather)
- [x] Map screen (rain radar with RainViewer)
- [x] Timeline screen (derived events)
- [x] Menu screen (saved regions, supporters club, about)
- [x] Settings screen (accessibility, notifications)
- [x] Sri Lanka localization (25 districts, 6 alert types, monsoons)
- [x] Island-wide / District toggle
- [x] Location search with GPS fallback
- [x] Hive caching with staleness indicators
- [x] Colour vision modes (3 modes)
- [x] Text size and font weight scaling

### Planned — DMC Alert Integration
See [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md):
- Real multi-source alert aggregation (Open-Meteo flood, GDACS cyclone/tsunami, ReliefWeb)
- Dedicated AlertBloc for Home + Timeline
- Backend alert aggregation engine
- Replace derived alerts with real alert pipeline

### Future
- [ ] Crisis Mapping (entity defined, not implemented)
- [ ] Push notifications (package included, not wired up)
- [ ] Earthquake Early Warning (not implemented)
- [ ] Home screen / lock screen widgets (not implemented)
- [ ] Sinhala / Tamil language support
- [ ] Real DMC alert feed integration
- [ ] Offline map tile caching
- [ ] Server-side caching proxy for multi-user scale

---

## 13. Privacy & Security Requirements

| Req ID | Requirement | Implementation |
|--------|-------------|----------------|
| PRIV-01 | API key not exposed to client | Stored in gitignored `.env`; loaded via `flutter_dotenv` and exposed through `ApiConstants` |
| PRIV-02 | No analytics SDK | No Firebase Analytics, Mixpanel, or similar |
| PRIV-03 | No advertising SDK | No AdMob, no Meta Audience Network |
| PRIV-04 | No user account required | App functions fully without registration |
| PRIV-05 | GPS coordinates sent only to third-party APIs | Location → WeatherAPI.com + MapTiler; user controls GPS via Local mode |
| PRIV-06 | Location history not stored remotely | Cached on-device in Hive only |
| PRIV-07 | Uninstall clears all data | No remote data deletion needed (no user account) |

---

## 14. Non-Functional Requirements

### Performance

| Metric | Target |
|--------|--------|
| App cold start to Home screen | < 2 seconds |
| Weather data refresh (cache hit) | < 100ms |
| Weather data refresh (network) | < 1.5 seconds |
| Map tile load | < 500ms per tile |
| Scroll frame rate | 60 fps |

### Offline Behaviour

| Feature | Offline Behaviour |
|---------|-----------------|
| Home screen | Shows last cached weather with stale data banner |
| Map | Shows cached tiles (no rain overlay) |
| Timeline | Shows last derived events from cached weather |
| Weather screen | Shows cached weather data |

### App Size

| Target | Value |
|--------|-------|
| APK / IPA | < 50 MB |

---

## 15. Accessibility Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| ACC-01 | All interactive elements have semantic labels | Partial |
| ACC-02 | Minimum touch target 48×48dp | Enforced via `AppConstants.minTouchTarget` |
| ACC-03 | WCAG 2.1 AA contrast ratio (4.5:1 for text) | Dark theme has high contrast |
| ACC-04 | No information conveyed by colour alone | Severity always paired with label text |
| ACC-05 | VoiceOver / TalkBack support | Not yet tested |
| ACC-06 | Reduce Motion support | Not yet implemented |
| ACC-07 | Font size scaling | 6 levels (0.75× to 1.5×) |
| ACC-08 | Font weight scaling | 3 levels (normal, medium, bold) |
| ACC-09 | Colour vision modes | 3 modes selectable in Settings |
| ACC-10 | High contrast mode | 3 levels selectable in Settings |

---

## 16. Open Questions & Risks

| # | Question / Risk | Mitigation |
|---|-----------------|-----------|
| R1 | **WeatherAPI.com call volume** — generous free tier (1M calls/month) | Dio + Hive cache minimise repeat calls per location |
| R2 | **No backend for offline scenarios** — if internet drops, only cache is available | Hive cache provides offline fallback for all screens |
| R3 | **No real alert data source for Sri Lanka** — DMC has no public API | Multi-source aggregation planned (see DMC integration plan); derive from weather thresholds in the meantime |
| R4 | **RainViewer API reliability** — free tier, no SLA | Graceful degradation: show map without radar overlay |
| R5 | **Font loading** — google_fonts requires network on first launch | Bundle Inter font as asset for offline-first reliability |
| R6 | **Crisis Mapping abuse** — no auth system for user-submitted data | Not yet implemented; will need moderation when built |
| R7 | **Map tile costs** — CartoDB free tier limits | Monitor usage; OpenStreetMap tile fallback available |
| R8 | **weather_detail_screen.dart** — uses hardcoded placeholder data | Needs wiring to WeatherBloc for real data |

---

## Appendix A — Key File Reference

| File | Purpose |
|------|---------|
| [`lib/main.dart`](lib/main.dart) | App entry, DI init, MaterialApp.router setup |
| [`lib/core/constants/app_sl_constants.dart`](lib/core/constants/app_sl_constants.dart) | Sri Lanka data: districts, cities, alert types, map bounds, monsoons |
| [`lib/core/utils/weather_alert_deriver.dart`](lib/core/utils/weather_alert_deriver.dart) | Threshold-based alert derivation from weather data |
| [`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart) | Dark/light ThemeData with accessibility overrides |
| [`lib/core/router/app_router.dart`](lib/core/router/app_router.dart) | GoRouter with ShellRoute (5 tabs) + weather-detail push route |
| [`lib/core/di/injection.dart`](lib/core/di/injection.dart) | get_it service locator registration |
| [`lib/data/remote/weatherapi/weather_api_client.dart`](lib/data/remote/weatherapi/weather_api_client.dart) | Dio client for WeatherAPI.com /forecast.json |
| [`lib/data/remote/maptiler/maptiler_geocoding_client.dart`](lib/data/remote/maptiler/maptiler_geocoding_client.dart) | Dio client for MapTiler geocoding |
| [`lib/data/local/hive/hive_service.dart`](lib/data/local/hive/hive_service.dart) | Hive box management |
| [`lib/data/repositories/weather_repository_impl.dart`](lib/data/repositories/weather_repository_impl.dart) | Weather repo with caching, GPS, serialization |
| [`lib/presentation/blocs/weather/weather_bloc.dart`](lib/presentation/blocs/weather/weather_bloc.dart) | WeatherBloc with district-aware loading |
| [`lib/presentation/blocs/settings/settings_bloc.dart`](lib/presentation/blocs/settings/settings_bloc.dart) | SettingsBloc for user preferences |
| [`lib/presentation/widgets/national_local_toggle.dart`](lib/presentation/widgets/national_local_toggle.dart) | Island-wide / District toggle |
| [`lib/presentation/widgets/main_scaffold.dart`](lib/presentation/widgets/main_scaffold.dart) | ShellRoute scaffold with 5-tab bottom nav |
| [`plans/dmc_alert_integration_plan.md`](plans/dmc_alert_integration_plan.md) | Architectural plan for real alert pipeline |
| [`plans/sri_lanka_localization_plan.md`](plans/sri_lanka_localization_plan.md) | Completed SL localization plan |

---

## Appendix B — Design Tokens (Flutter ThemeData)

```dart
// Actual dark theme structure from AppTheme.darkTheme()
ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: Color(0xFF000000),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF00BCD4),       // Cyan accent
    secondary: Color(0xFF00E5FF),
    surface: Color(0xFF1A1A1A),
    error: Color(0xFFFF1744),
  ),
  // Cards: zero elevation, 1px #2A2A2A border, 12dp radius
  // NavigationBar: transparent indicator, 64dp height
  // Text: google_fonts Inter, all sizes × textSizeScale multiplier
)
```

---

*This PRD reflects the codebase as of May 27, 2026. All specifications are subject to revision as development progresses.*
*Weather data: WeatherAPI.com (direct from client). Map tiles: MapTiler hybrid. Radar overlay: OpenWeatherMap precipitation tiles.*
