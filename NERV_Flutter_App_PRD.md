# Product Requirements Document
# NERV Disaster Prevention — Flutter App

**Document Version:** 2.0  
**Date:** April 24, 2026  
**Platform:** Flutter (iOS & Android)  
**Inspired By:** nerv.app/en — Gehirn Inc.  
**Weather Data Provider:** Open-Meteo API (Free, No API Key Required)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Goals](#2-product-vision--goals)
3. [Target Users & Personas](#3-target-users--personas)
4. [Design System](#4-design-system)
   - 4.1 Brand Identity
   - 4.2 Colour Palette
   - 4.3 Typography
   - 4.4 Spacing & Grid
   - 4.5 Iconography
   - 4.6 Elevation & Shadows
   - 4.7 Motion & Animation
   - 4.8 Component Library
   - 4.9 Accessibility Tokens
5. [Screen Architecture & UI Specifications](#5-screen-architecture--ui-specifications)
   - 5.1 Navigation Structure
   - 5.2 Home Screen
   - 5.3 Map Screen
   - 5.4 Timeline Screen
   - 5.5 Weather Detail Screen
   - 5.6 Settings Screen
   - 5.7 Crisis Mapping Screen
   - 5.8 Notification Detail Screen
6. [Feature Specifications](#6-feature-specifications)
7. [Weather API Integration — Open-Meteo](#7-weather-api-integration--open-meteo)
8. [Flutter Architecture](#8-flutter-architecture)
9. [Flutter Package Dependencies](#9-flutter-package-dependencies)
10. [Notification System](#10-notification-system)
11. [Privacy & Security Requirements](#11-privacy--security-requirements)
12. [Non-Functional Requirements](#12-non-functional-requirements)
13. [Accessibility Requirements](#13-accessibility-requirements)
14. [Release Milestones](#14-release-milestones)
15. [Open Questions & Risks](#15-open-questions--risks)

---

## 1. Executive Summary

This PRD defines the complete requirements for a Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. The app delivers real-time weather data, emergency-level alerts, hazard mapping, and community-powered crisis information in a tactical, high-contrast dark UI.

**Weather data** is provided exclusively through the **Open-Meteo API** — a free, open-source, no-API-key-required service delivering forecasts from national weather services worldwide (NOAA, DWD, ECMWF, JMA, MeteoFrance).

The app is designed to function as both an everyday weather companion and an emergency information hub, with an uncompromisingly clean aesthetic and a privacy-first data model.

---

## 2. Product Vision & Goals

### Vision
> "Before the shake. Before the flood. Before the danger — you already know."

### Goals

| # | Goal | KPI |
|---|------|-----|
| G1 | Deliver weather & alerts faster than native OS weather widgets | Time-from-event to notification < 5s |
| G2 | Zero advertisements, zero tracking | No ad SDK in the app bundle |
| G3 | Fully functional offline for cached data | Core screens load with stale data when offline |
| G4 | Accessibility-first design | WCAG 2.1 AA compliance |
| G5 | Minimal battery footprint | Background battery use < 1% per hour |
| G6 | Open-Meteo free tier compliance | < 10,000 API calls/day with smart caching |

---

## 3. Target Users & Personas

### Persona 1 — "The Daily Commuter" (Primary)
- Age: 25–45, urban resident
- Need: Quick glance at rain radar and temperature before leaving home
- Pain point: Too many weather apps cluttered with ads and irrelevant content
- Uses: Home screen widget, rain radar, daily forecast

### Persona 2 — "The Emergency-Aware Resident" (Primary)
- Age: 30–60, lives in disaster-prone area
- Need: Immediate push alert for incoming storms, floods, or quakes
- Pain point: Delayed or missed alerts from standard OS weather
- Uses: Critical alerts, hazard map, timeline

### Persona 3 — "The Accessibility User" (Secondary)
- Age: Any, has colour vision deficiency or low vision
- Need: App that doesn't rely solely on colour for critical info
- Pain point: Most weather apps use red/green coding only
- Uses: High-contrast theme, screen reader layout, adjustable text

### Persona 4 — "The Community Contributor" (Secondary)
- Age: 20–55, tech-savvy, community-minded
- Need: Ability to post and verify disaster relief locations
- Uses: Crisis Mapping layer, Watch/subscribe feature

---

## 4. Design System

### 4.1 Brand Identity

The visual language is inspired by NERV's tactical operations interface — dark, structured, data-dense, and built for rapid information parsing. The design avoids decorative elements and prioritises legibility and urgency signalling.

**Design Principles:**
1. **Clarity over decoration** — Every pixel serves information
2. **Urgency hierarchy** — Colour and size signal severity, not aesthetics
3. **Night-mode first** — Dark theme is the canonical design; light is secondary
4. **Motion is informative** — Animations signal real-time data changes, not flourishes
5. **No noise** — No ads, no banners, no promotional elements ever

---

### 4.2 Colour Palette

#### Base (Dark Theme — Primary)

| Token | Hex | Usage |
|-------|-----|-------|
| `color-bg-primary` | `#0A0C10` | Main background, scaffold |
| `color-bg-surface` | `#12151C` | Cards, panels, bottom sheets |
| `color-bg-elevated` | `#1A1E29` | Elevated cards, modal backgrounds |
| `color-bg-overlay` | `#232836` | Map overlays, drawer backgrounds |
| `color-border-default` | `#2A2F3E` | Card borders, dividers |
| `color-border-subtle` | `#1E2230` | Subtle separators |

#### Brand Accent

| Token | Hex | Usage |
|-------|-----|-------|
| `color-accent-primary` | `#FF6B00` | Primary CTA, active states, brand accent |
| `color-accent-secondary` | `#FF9500` | Secondary highlights, hover states |
| `color-accent-glow` | `#FF6B0033` | Glow effects on accent elements |

#### Severity Scale (Critical to Informational)

| Token | Hex | Label | Used For |
|-------|-----|-------|----------|
| `color-severity-critical` | `#FF1744` | CRITICAL | Major Tsunami Warning, Extreme Weather |
| `color-severity-emergency` | `#FF6D00` | EMERGENCY | EEW, High-level Tornado, Major Flooding |
| `color-severity-warning` | `#FFC400` | WARNING | Weather Warning, Hazard Level 4 |
| `color-severity-advisory` | `#00E5FF` | ADVISORY | Weather Advisory, Watch |
| `color-severity-info` | `#69F0AE` | INFO | Routine updates, Forecast |
| `color-severity-calm` | `#42A5F5` | CALM | Clear sky, no alerts |

#### Text Colours

| Token | Hex | Usage |
|-------|-----|-------|
| `color-text-primary` | `#F0F2F8` | Primary body text, headings |
| `color-text-secondary` | `#8B95B0` | Secondary labels, captions |
| `color-text-tertiary` | `#4A5270` | Disabled text, placeholder |
| `color-text-inverse` | `#0A0C10` | Text on bright backgrounds |
| `color-text-link` | `#FF9500` | Hyperlinks, tappable text |

#### Light Theme Overrides

| Token | Hex | Usage |
|-------|-----|-------|
| `color-bg-primary` | `#F4F6FA` | Main background |
| `color-bg-surface` | `#FFFFFF` | Cards, panels |
| `color-bg-elevated` | `#EEF0F6` | Elevated cards |
| `color-border-default` | `#D0D5E8` | Card borders |
| `color-text-primary` | `#0F1120` | Body text |
| `color-text-secondary` | `#5A6280` | Labels |

#### Colour Vision Accessible Overrides

**Protanopia/Deuteranopia (Red–Green):**
- Replace `color-severity-critical` with `#0072B2` (Blue)
- Replace `color-severity-info` with `#E69F00` (Orange)

**Tritanopia (Blue–Yellow):**
- Replace `color-severity-advisory` with `#CC79A7` (Pink)
- Replace `color-severity-calm` with `#009E73` (Teal)

---

### 4.3 Typography

**Primary Typeface:** `Inter` (open-source, SIL OFL 1.1)  
**Monospace Typeface:** `JetBrains Mono` (data readouts, countdown timers, coordinates)

```dart
// pubspec.yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
      - asset: assets/fonts/Inter-Medium.ttf   weight: 500
      - asset: assets/fonts/Inter-SemiBold.ttf weight: 600
      - asset: assets/fonts/Inter-Bold.ttf     weight: 700
  - family: JetBrainsMono
    fonts:
      - asset: assets/fonts/JetBrainsMono-Regular.ttf
      - asset: assets/fonts/JetBrainsMono-Bold.ttf   weight: 700
```

#### Type Scale

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `text-display` | 32sp | Bold (700) | 40sp | Alert headlines, major readouts |
| `text-headline-lg` | 24sp | SemiBold (600) | 32sp | Screen titles |
| `text-headline-md` | 20sp | SemiBold (600) | 28sp | Section headers, card titles |
| `text-headline-sm` | 17sp | SemiBold (600) | 24sp | Card sub-headers |
| `text-body-lg` | 16sp | Regular (400) | 24sp | Primary body content |
| `text-body-md` | 14sp | Regular (400) | 20sp | Secondary body, descriptions |
| `text-body-sm` | 12sp | Regular (400) | 18sp | Captions, metadata |
| `text-label-lg` | 14sp | Medium (500) | 20sp | Button labels, navigation labels |
| `text-label-sm` | 11sp | Medium (500) | 16sp | Tags, chips, badge text |
| `text-mono-lg` | 20sp | Bold (700) | 28sp | Countdown timers, temperature readouts |
| `text-mono-sm` | 13sp | Regular (400) | 18sp | Coordinates, technical data |

#### Text Size Scale (User-Adjustable)

```dart
enum TextSizeScale { xSmall, small, normal, large, xLarge, xxLarge }
// Multipliers: 0.75, 0.875, 1.0, 1.125, 1.25, 1.5
```

#### Font Weight Scale (User-Adjustable)

```dart
enum FontWeightScale { normal, medium, bold }
// Maps to: FontWeight.w400, FontWeight.w500, FontWeight.w700
```

---

### 4.4 Spacing & Grid

**Base unit:** 4dp

| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4dp | Micro gaps (icon-to-label) |
| `space-2` | 8dp | Component internal padding (tight) |
| `space-3` | 12dp | Component internal padding (standard) |
| `space-4` | 16dp | Card padding, section gaps |
| `space-5` | 20dp | List item vertical padding |
| `space-6` | 24dp | Screen horizontal margin |
| `space-8` | 32dp | Section vertical spacing |
| `space-10` | 40dp | Large section gaps |
| `space-12` | 48dp | Bottom nav clearance |

**Border Radius:**

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 4dp | Tags, chips, small badges |
| `radius-sm` | 8dp | Buttons, small cards |
| `radius-md` | 12dp | Standard cards, panels |
| `radius-lg` | 16dp | Bottom sheets, modal cards |
| `radius-xl` | 24dp | Hero cards, large panels |
| `radius-full` | 999dp | Pills, circular elements |

**Screen Layout:**

```
Horizontal margin:  24dp (default), 16dp (compact)
Content max-width:  600dp (tablet)
Bottom nav height:  64dp + safe area inset
Top bar height:     56dp + status bar inset
Card elevation gap: 12dp between cards
```

---

### 4.5 Iconography

**Icon Library:** `Material Symbols` (outlined, weight 200–400 for minimal aesthetic)  
**Supplementary:** Custom SVG icons for disaster-specific concepts

| Icon Purpose | Material Symbol | Custom SVG |
|-------------|-----------------|------------|
| Earthquake | `vibration` | — |
| Tsunami | — | `icon_tsunami.svg` |
| Volcano | `local_fire_department` | `icon_volcano.svg` |
| Rain radar | `radar` | — |
| Typhoon | `cyclone` | — |
| Lightning | `bolt` | — |
| Flood/River | `water` | — |
| Shelter | `emergency_home` | — |
| J-Alert | `campaign` | — |
| Crisis Map pin | `location_on` | — |
| Timeline | `timeline` | — |
| Watch/Subscribe | `notifications` | — |

**Icon Sizes:**

| Context | Size |
|---------|------|
| Navigation bar | 24dp |
| Card leading icon | 20dp |
| Alert header icon | 32dp |
| Critical alert icon | 48dp |
| Map pin | 36dp |

---

### 4.6 Elevation & Shadows

The dark theme uses **border-based elevation** rather than shadow-based (shadows are invisible on dark backgrounds). Light theme uses standard Material elevation shadows.

```dart
// Dark Theme: border-only elevation
BoxDecoration cardDecoration(int level) => BoxDecoration(
  color: level == 0 ? colorBgSurface :
         level == 1 ? colorBgElevated :
                      colorBgOverlay,
  border: Border.all(color: colorBorderDefault, width: 1),
  borderRadius: BorderRadius.circular(radiusMd),
);

// Light Theme: material elevation + subtle shadow
BoxShadow lightElevation(int dp) => BoxShadow(
  color: Colors.black.withOpacity(0.06 * dp),
  blurRadius: dp * 4.0,
  offset: Offset(0, dp * 1.5),
);
```

---

### 4.7 Motion & Animation

| Motion Token | Duration | Curve | Usage |
|-------------|----------|-------|-------|
| `anim-instant` | 0ms | — | State switches without transition |
| `anim-fast` | 150ms | `easeOut` | Icon state changes, toggle switches |
| `anim-standard` | 250ms | `easeInOut` | Card expand/collapse, tab switches |
| `anim-slow` | 400ms | `easeInOut` | Screen transitions, modal appear |
| `anim-alert-pulse` | 800ms | `easeInOut` (loop) | Critical alert pulse ring |
| `anim-radar-sweep` | 2000ms | `linear` (loop) | Radar sweep on map |
| `anim-countdown` | 1000ms | `linear` (loop) | EEW countdown tick |

**Reduce Motion:** When the OS "Reduce Motion" accessibility setting is active, all animations collapse to `anim-instant` except critical alert pulses, which use a static high-contrast indicator instead.

---

### 4.8 Component Library

#### A. Alert Banner

```
┌─────────────────────────────────────────┐
│ [SEVERITY ICON]  ALERT TYPE             │
│                  Headline text here     │
│                  Sub-detail line        │
│                  [HH:MM] • [Location]   │
└─────────────────────────────────────────┘
```

- Background: `color-severity-*` at 15% opacity with left border 4dp solid `color-severity-*`
- Icon: 32dp, severity colour
- Headline: `text-headline-sm`, `color-text-primary`
- Sub-detail: `text-body-sm`, `color-text-secondary`
- Tap target: entire card → navigates to detail screen

#### B. Weather Info Card

```
┌──────────────────────────────────────┐
│ [Weather Icon]  24°C    Partly Cloudy│
│ ─────────────────────────────────────│
│ Humidity 62%  Wind 12km/h  Rain 0mm  │
│ ─────────────────────────────────────│
│ ▼ 7-Day Forecast (chevron)           │
└──────────────────────────────────────┘
```

#### C. Countdown Timer Widget

```
┌───────────────────────────────┐
│ Earthquake Early Warning      │
│ ╔════════════════════════╗    │
│ ║       00:07            ║    │  ← JetBrains Mono, 48sp
│ ╚════════════════════════╝    │
│  Seconds until shaking        │
│  Predicted intensity: Int. 5  │
└───────────────────────────────┘
```

- Timer text: `text-mono-lg` at 48sp, `color-severity-emergency`
- Pulse ring animates at `anim-alert-pulse`
- Background dims the rest of the app to 40% opacity when active

#### D. Severity Chip

```dart
Widget severityChip(String label, SeverityLevel level) => Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: level.color.withOpacity(0.15),
    border: Border.all(color: level.color, width: 1),
    borderRadius: BorderRadius.circular(radiusXs),
  ),
  child: Text(label, style: textLabelSm.copyWith(color: level.color)),
);
```

#### E. Map Overlay Button (Floating Action Cluster)

```
         ┌─────┐
         │ 🗺  │  ← Toggle map layers
         └─────┘
         ┌─────┐
         │ 📍  │  ← My location
         └─────┘
         ┌─────┐
         │ ⚡  │  ← Lightning toggle
         └─────┘
```

- 48dp square, `color-bg-elevated`, `radius-sm`
- Right-aligned, 16dp from screen edge

#### F. Timeline Event Row

```
  [Icon] ── [HH:MM] ─────────────────
           EVENT TYPE                  
           Location or area detail     
           [Severity Chip] [Duration]  
```

#### G. Bottom Navigation Bar

```
┌─────────────────────────────────────┐
│  🏠 Home  │  🗺 Map  │ 📋 Timeline │ ⚙ Menu │
└─────────────────────────────────────┘
```

- Height: 64dp + bottom safe area
- Active: `color-accent-primary` icon + label
- Inactive: `color-text-tertiary`
- Background: `color-bg-surface` with top border `color-border-default`

---

### 4.9 Accessibility Tokens

```dart
const double minTouchTarget = 48.0;   // minimum tap area
const double focusRingWidth = 2.0;    // keyboard focus ring width
const Color focusRingColor = Color(0xFF00E5FF);
const double minContrastRatio = 4.5;  // WCAG AA
```

---

## 5. Screen Architecture & UI Specifications

### 5.1 Navigation Structure

```
App Root
├── Bottom Navigation Bar
│   ├── [Tab 1] Home
│   ├── [Tab 2] Map
│   ├── [Tab 3] Timeline
│   └── [Tab 4] Settings/Menu
│
├── Overlay Screens (push navigation)
│   ├── Alert Detail Screen
│   ├── Weather Detail Screen
│   ├── Crisis Mapping Screen
│   └── Notification History Screen
│
└── System Overlays
    ├── Critical Alert Full-Screen Modal
    └── Onboarding Flow (first launch)
```

---

### 5.2 Home Screen

**Purpose:** Consolidated at-a-glance view of current weather + active alerts, sorted by urgency.

**Layout (top to bottom):**

```
┌─────────────────────────────────────┐
│ NERV          [Bell] [Location ▾]   │  ← Top bar (56dp)
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ 📍 Colombo, Sri Lanka         │   │  ← Location + Current time
│ │    28°C  ⛅ Partly Cloudy     │   │
│ │    Feels like 32°C            │   │
│ │    H: 35° / L: 24°            │   │
│ └───────────────────────────────┘   │
│                                     │
│ ── ACTIVE ALERTS ──────────────────│
│ [Critical] Heavy Rain Warning ›     │  ← Alert Banner (red/amber)
│ [Advisory] Coastal Wind Watch ›     │
│                                     │
│ ── WEATHER OVERVIEW ───────────────│
│ [Rain Radar Card]     → ›           │
│ [Wind Card]           → ›           │
│ [Humidity/UV Card]    → ›           │
│                                     │
│ ── 7-DAY FORECAST ─────────────────│
│ Mon  ⛅ 35°/24°  Tue  🌧 30°/22°  │
│ Wed  🌩 27°/21°  Thu  ⛅ 32°/23°  │
│ ...                                 │
│                                     │
│ ── CRISIS MAP NEARBY ──────────────│
│ [Crisis Map Preview Card]      ›    │
└─────────────────────────────────────┘
│  🏠 Home  │  🗺 Map  │ 📋 Timeline │ ⚙ │
└─────────────────────────────────────┘
```

**Behaviour:**
- Alert banners auto-sort by severity; Critical always first
- Weather cards auto-refresh every 10 minutes (Open-Meteo polling)
- Pull-to-refresh triggers an immediate API refresh
- Active alert count badge on Bell icon in top bar

---

### 5.3 Map Screen

**Purpose:** Interactive map with toggleable disaster and weather overlay layers.

**Layout:**

```
┌─────────────────────────────────────┐
│ [Search bar: "Search location..."]  │
├─────────────────────────────────────┤
│                                     │
│        [Interactive Map]            │
│        (flutter_map / Mapbox)       │
│                                     │
│                       ┌───┐         │
│                       │ 🗺│ Layers  │
│                       ├───┤         │
│                       │ 📍│ Locate  │
│                       └───┘         │
├─────────────────────────────────────┤
│ ← Layer Chips (horizontal scroll) → │
│ [Rain][Hazard][Crisis][Wind][Temp]  │
└─────────────────────────────────────┘
```

**Map Layers (toggleable):**

| Layer | Data Source | Update Interval |
|-------|------------|-----------------|
| Rain Radar | Open-Meteo precipitation | 10 min |
| Temperature Grid | Open-Meteo temperature | 1 hour |
| Wind Speed | Open-Meteo wind | 1 hour |
| Hazard Zones | Static GeoJSON (cached) | On-demand |
| Crisis Mapping | User-submitted (real-time) | 5 min |
| Lightning | Open-Meteo lightning | 1 min |

---

### 5.4 Timeline Screen

**Purpose:** Chronological feed of all events in the last 72 hours.

**Layout:**

```
┌─────────────────────────────────────┐
│ Timeline              [Filter ▾]    │
├─────────────────────────────────────┤
│ TODAY                               │
│  │                                  │
│  ● 14:32  ⚠ Heavy Rain Warning      │
│  │        Western Province          │
│  │        [WARNING] Issued          │
│  │                                  │
│  ● 11:15  🌊 Coastal Advisory       │
│  │        [ADVISORY] Issued         │
│  │                                  │
│ YESTERDAY                           │
│  │                                  │
│  ● 22:44  ⚠ Heavy Rain Warning      │
│            [WARNING] LIFTED ✓       │
└─────────────────────────────────────┘
```

**Filter Options:** All / Earthquakes / Tsunami / Weather / Volcanic / J-Alert / Crisis Map

---

### 5.5 Weather Detail Screen

**Purpose:** Full expanded view of weather data for a location.

**Sections:**
1. Current conditions hero (temperature, icon, feels-like, UV, humidity, wind)
2. Hourly forecast (horizontal scroll, 24 hours, Chart with precipitation probability)
3. 7-day forecast list
4. Rain radar mini-map (tappable → full Map screen on Rain layer)
5. Sunrise/Sunset card
6. Wind speed/direction rose
7. JMA synoptic chart (static image, updated every 6h)

---

### 5.6 Settings Screen

**Sections:**

```
┌─────────────────────────────────────┐
│ ← Settings                          │
├─────────────────────────────────────┤
│ REGISTERED LOCATIONS                │
│ [+] Add location      [My GPS ✓]    │
│ ┌──────────────────────────────┐    │
│ │ 📍 Colombo                   │    │
│ │ 📍 Kandy              [×]    │    │
│ └──────────────────────────────┘    │
│                                     │
│ APPEARANCE                          │
│ Theme          [Dark ●] [Light ○]   │
│ Colour Vision  [Normal] [P/D] [T]   │
│ Contrast       [Low] [Normal] [High]│
│ Font Size       ───●────────────    │
│ Font Weight    [Normal] [Med] [Bold]│
│ Screen Reader   OFF ●               │
│                                     │
│ NOTIFICATIONS                       │
│ Critical Alerts  ●                  │
│ Earthquake       ●                  │
│ Tsunami          ●                  │
│ Weather Warning  ●                  │
│ Hazard Level     ●                  │
│ J-Alert          ●                  │
│                                     │
│ TEST NOTIFICATION                   │
│ [Send Test Alert]                   │
│                                     │
│ LANGUAGE         EN ● │ JA ○        │
│                                     │
│ ABOUT / PRIVACY POLICY              │
└─────────────────────────────────────┘
```

---

### 5.7 Crisis Mapping Screen

**Purpose:** Community-contributed disaster relief POI map.

**Layout:** Full-screen map with floating bottom sheet listing nearby POIs.

**Bottom Sheet (collapsed):**
```
── Crisis Map ─────────── ↑ Pull up
📍 6 points within 5km
[Shelter] [Water] [Toilet] [Road] [All]
```

**Bottom Sheet (expanded):**
```
┌──────────────────────────────────┐
│ 🏠 Colombo North Evacuation Ctr  │
│    0.8km away · Updated 2h ago   │
│    Capacity: 250 | Open ✓        │
│    [Watch] [Get Directions]      │
├──────────────────────────────────┤
│ 💧 Water Distribution — Pettah   │
│    1.2km away · Posted 4h ago    │
│    [Watch] [Get Directions]      │
└──────────────────────────────────┘
```

---

### 5.8 Notification Detail Screen

Full-page detail view triggered by tapping any push notification or alert banner.

**Content:**
- Severity badge + event type headline
- Affected area map (mini-map, not interactive)
- Issued time / Expiry time
- Detailed description text
- Recommended actions list
- Share button (system share sheet)

---

## 6. Feature Specifications

### F-01 Earthquake Early Warning (EEW)

| Field | Spec |
|-------|------|
| Trigger | Simulated via periodic Open-Meteo seismic API (for production: integrate USGS GeoJSON feed) |
| Alert Type | Critical Alert (bypasses Do Not Disturb) |
| UI | Full-screen takeover modal with pulsing red border, countdown timer (JetBrains Mono), predicted intensity chip |
| Countdown | S-wave arrival countdown in seconds, tick every 1 second |
| Dismissal | Auto-dismisses after countdown reaches 0 + 10 seconds; manual dismiss available |
| REQ | EEW-01: Must function even when app is in background |

### F-02 Rain Radar

| Field | Spec |
|-------|------|
| Data | Open-Meteo Forecast API: `hourly=precipitation,precipitation_probability` |
| Range | ±1 hour historical, up to 15 hours forecast |
| Refresh | Every 10 minutes |
| UI | Colour gradient overlay on map (blue→cyan→yellow→red scale) |
| REQ | RADAR-01: Cached last result must display offline |

### F-03 Weather Forecasts

| Field | Spec |
|-------|------|
| Current | `current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,relative_humidity_2m,precipitation` |
| Hourly | `hourly=temperature_2m,precipitation_probability,precipitation,wind_speed_10m,uv_index` |
| Daily | `daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,sunrise,sunset,uv_index_max` |
| Forecast Range | 16 days (daily), 7 days shown in UI |
| Refresh | Every 60 minutes (hourly model updates) |

### F-04 Push Notifications (Weather Alerts)

| Event | Threshold | Priority |
|-------|-----------|----------|
| Heavy Rain | precipitation > 20mm/hr | High (sound) |
| Extreme Rain | precipitation > 50mm/hr | Critical (override silent) |
| High Wind | wind_speed > 60km/h | High |
| Storm | weather_code in [95,96,99] | Critical |
| UV Extreme | uv_index > 10 | Normal |
| Flash Flood | Open-Meteo Flood API: discharge spike | Critical |

### F-05 Crisis Mapping

| Field | Spec |
|-------|------|
| Post Types | Shelter, Water, Toilet (accessible flag), Road condition, Waste, Relief Supply |
| Geo-fence | Posts restricted to within 10km of device GPS |
| Auth | Supporters' Club member flag (local persisted token) |
| Moderation | Flag button on each pin; flagged items reviewed |
| Translation | libretranslate or on-device ML Kit translation (EN↔target language) |
| Watch | Subscribe to pin updates; local notification when pin is edited/deleted |

### F-06 Timeline

| Field | Spec |
|-------|------|
| Duration | 72 hours of events |
| Storage | SQLite (drift package) — persisted locally |
| Event Types | Weather alerts, earthquakes, crisis map updates, user actions |
| Grouping | Date sections; most recent first |
| Filter | By event type (chip filter row) |

### F-07 Widgets

| Platform | Widget | Content |
|----------|--------|---------|
| iOS 16+ | Lock screen (small) | Current temp + weather icon |
| iOS | Home screen (medium) | Temp, condition, 3-hour forecast |
| Android | Home screen | Temp, condition, rain probability |
| Implementation | `home_widget` Flutter package | — |

---

## 7. Weather API Integration — Open-Meteo

### 7.1 Why Open-Meteo

| Criterion | Open-Meteo |
|-----------|-----------|
| API key required | ❌ No |
| Cost (non-commercial) | Free |
| Rate limit | 10,000 calls/day, 5,000/hour, 600/min |
| Response time | < 10ms (CDN-backed) |
| Flutter SDK | `open_meteo` package (pub.dev) |
| Data freshness | Hourly model updates |
| Coverage | Global (NOAA, ECMWF, DWD, JMA, MeteoFrance) |
| Historical data | 80+ years |
| Uptime | 99.9% SLA |
| License | CC BY 4.0 (attribution required) |

### 7.2 API Endpoints Used

#### Forecast API (Primary)
```
GET https://api.open-meteo.com/v1/forecast
```

**Required Parameters:**
```
latitude={lat}&longitude={lon}
&current=temperature_2m,apparent_temperature,weather_code,
          wind_speed_10m,wind_direction_10m,relative_humidity_2m,
          precipitation,surface_pressure,cloud_cover,uv_index
&hourly=temperature_2m,precipitation_probability,precipitation,
        wind_speed_10m,wind_gusts_10m,weather_code,uv_index,
        visibility,relative_humidity_2m
&daily=weather_code,temperature_2m_max,temperature_2m_min,
       apparent_temperature_max,apparent_temperature_min,
       precipitation_sum,precipitation_probability_max,
       wind_speed_10m_max,wind_gusts_10m_max,
       sunrise,sunset,uv_index_max,shortwave_radiation_sum
&timezone=auto
&forecast_days=7
&wind_speed_unit=kmh
&precipitation_unit=mm
```

**Example Response (partial):**
```json
{
  "current": {
    "time": "2026-04-24T14:00",
    "temperature_2m": 28.4,
    "apparent_temperature": 32.1,
    "weather_code": 3,
    "wind_speed_10m": 12.5,
    "wind_direction_10m": 220,
    "relative_humidity_2m": 72,
    "precipitation": 0.0,
    "uv_index": 8.2
  },
  "hourly": { "time": [...], "temperature_2m": [...], ... },
  "daily": { "time": [...], "temperature_2m_max": [...], ... }
}
```

#### Geocoding API (Location Search)
```
GET https://geocoding-api.open-meteo.com/v1/search?name={query}&count=5&language=en
```

#### Air Quality API (UV + Pollution)
```
GET https://air-quality-api.open-meteo.com/v1/air-quality
?latitude={lat}&longitude={lon}
&hourly=us_aqi,pm2_5,pm10,uv_index,uv_index_clear_sky
```

#### Flood API (River discharge — crisis alerts)
```
GET https://flood-api.open-meteo.com/v1/flood
?latitude={lat}&longitude={lon}
&daily=river_discharge
&forecast_days=7
```

#### Historical Weather API (Timeline context)
```
GET https://archive-api.open-meteo.com/v1/archive
?latitude={lat}&longitude={lon}
&start_date={date-3d}&end_date={today}
&hourly=temperature_2m,precipitation,weather_code
```

### 7.3 Caching Strategy

```dart
// Cache TTLs
const currentWeatherTTL    = Duration(minutes: 10);
const hourlyForecastTTL    = Duration(hours: 1);
const dailyForecastTTL     = Duration(hours: 3);
const airQualityTTL        = Duration(hours: 1);
const floodDataTTL         = Duration(hours: 6);
const geocodingTTL         = Duration(days: 7);   // location rarely changes
```

**Cache Implementation:** `hive` (NoSQL local storage) + `dio_cache_interceptor`

```dart
// Dio + cache interceptor setup
final cacheStore = HiveCacheStore('./hive_cache');
final cachePolicy = CachePolicy.forceCache;

final dio = Dio()
  ..interceptors.add(
    DioCacheInterceptor(options: CacheOptions(
      store: cacheStore,
      policy: CachePolicy.refreshForceCache,
      maxStale: const Duration(hours: 6), // serve stale if offline
    )),
  );
```

### 7.4 API Call Budget

| API Call Type | Frequency | Daily Calls (1 user) | 1000 Users |
|--------------|-----------|----------------------|------------|
| Current weather | Every 10 min | 144 | 144,000 |
| Hourly forecast | Every 1 hour | 24 | 24,000 |
| Daily forecast | Every 3 hours | 8 | 8,000 |
| Air quality | Every 1 hour | 24 | 24,000 |
| Geocoding | On search | ~2 | ~2,000 |

> **Budget Note:** For >100 users sharing a backend, implement a **server-side proxy** that calls Open-Meteo once per location per TTL window and caches the response — reducing calls to Open-Meteo by 95%+ while keeping the app free for end-users. For commercial use, upgrade to Open-Meteo's paid API (from ~$20/month).

### 7.5 Weather Code Mapping

Open-Meteo uses WMO Weather Code (WW) standard:

| Code | Description | App Icon | Severity |
|------|-------------|----------|----------|
| 0 | Clear sky | ☀️ | Calm |
| 1–3 | Partly cloudy | ⛅ | Calm |
| 45–48 | Fog | 🌫️ | Advisory |
| 51–55 | Drizzle | 🌦️ | Info |
| 61–65 | Rain | 🌧️ | Info |
| 71–75 | Snow | 🌨️ | Info |
| 80–82 | Rain showers | 🌧️ | Advisory |
| 85–86 | Snow showers | 🌨️ | Advisory |
| 95 | Thunderstorm | ⛈️ | Warning |
| 96–99 | Thunderstorm + hail | ⛈️ | Emergency |

---

## 8. Flutter Architecture

### 8.1 Architecture Pattern: Clean Architecture + BLoC

```
lib/
├── core/
│   ├── constants/        # colours, typography, spacing tokens
│   ├── theme/            # ThemeData, dark/light/accessible themes
│   ├── router/           # GoRouter route definitions
│   ├── di/               # get_it service locator
│   └── utils/            # formatters, extensions, helpers
│
├── data/
│   ├── remote/
│   │   ├── open_meteo/   # OpenMeteo API client (dio)
│   │   └── crisis_map/   # Crisis mapping REST client
│   ├── local/
│   │   ├── hive/         # Hive boxes (weather cache, settings)
│   │   └── drift/        # SQLite database (timeline, crisis pins)
│   └── repositories/     # Implementations of domain repo interfaces
│
├── domain/
│   ├── entities/         # WeatherData, Alert, CrisisPin, TimelineEvent
│   ├── repositories/     # Abstract repo interfaces
│   └── usecases/         # GetCurrentWeather, GetForecast, PostCrisisPin...
│
├── presentation/
│   ├── blocs/            # WeatherBloc, AlertBloc, CrisisMapBloc, SettingsBloc
│   ├── screens/
│   │   ├── home/
│   │   ├── map/
│   │   ├── timeline/
│   │   ├── weather_detail/
│   │   ├── crisis_map/
│   │   └── settings/
│   └── widgets/          # Shared reusable widgets (AlertBanner, WeatherCard...)
│
└── main.dart
```

### 8.2 State Management

| Layer | Tool |
|-------|------|
| UI State | `flutter_bloc` (BLoC pattern) |
| Global App State | `get_it` + `injectable` (service locator) |
| Persistent Settings | `hive` |
| Local DB (timeline) | `drift` (type-safe SQLite) |
| Navigation | `go_router` |

### 8.3 BLoC States Example — WeatherBloc

```dart
abstract class WeatherState {}
class WeatherInitial extends WeatherState {}
class WeatherLoading extends WeatherState {}
class WeatherLoaded extends WeatherState {
  final WeatherData current;
  final List<HourlyData> hourly;
  final List<DailyData> daily;
  final bool isStaleCache;
}
class WeatherError extends WeatherState {
  final String message;
  final WeatherData? cachedData; // show stale if available
}
```

---

## 9. Flutter Package Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5
  get_it: ^8.0.0
  injectable: ^2.4.2

  # Navigation
  go_router: ^14.2.0

  # Networking
  dio: ^5.4.3
  dio_cache_interceptor: ^3.5.0
  dio_cache_interceptor_hive_store: ^3.2.1
  connectivity_plus: ^6.0.3

  # Local Storage
  hive_flutter: ^1.1.0
  drift: ^2.19.1
  sqlite3_flutter_libs: ^0.5.22

  # Maps
  flutter_map: ^7.0.0
  latlong2: ^0.9.1

  # Location
  geolocator: ^12.0.0
  geocoding: ^3.0.0

  # Notifications
  flutter_local_notifications: ^17.2.1
  firebase_messaging: ^15.1.4   # FCM for server-push (optional)

  # Widgets
  home_widget: ^0.7.0

  # UI & Design
  google_fonts: ^6.2.1          # Inter (fallback if bundled fonts fail)
  flutter_svg: ^2.0.10
  shimmer: ^3.0.0               # Loading skeletons
  fl_chart: ^0.69.0             # Weather charts (hourly forecast)
  cached_network_image: ^3.4.0

  # Permissions
  permission_handler: ^11.3.1

  # Internationalization
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

  # Date/Time
  timeago: ^3.6.1

  # Utilities
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  rxdart: ^0.27.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.10
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.1
  drift_dev: ^2.19.1
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
  flutter_lints: ^4.0.0
```

---

## 10. Notification System

### 10.1 Architecture

```
Open-Meteo API ──→ Background Fetch (WorkManager/BGTaskScheduler)
                         │
                         ├── Parse weather codes & thresholds
                         │
                         ├── Compare to user's saved threshold prefs
                         │
                         └── flutter_local_notifications
                                    │
                                    ├── Critical Alert (iOS) / High Priority (Android)
                                    ├── Normal notification
                                    └── Silent notification (data refresh)
```

### 10.2 Background Fetch

```dart
// Android: WorkManager via workmanager package
// iOS: BGAppRefreshTask via background_fetch package

@pragma('vm:entry-point')
Future<void> backgroundFetchCallback() async {
  final weatherRepo = getIt<WeatherRepository>();
  final alertService = getIt<AlertEvaluationService>();

  final data = await weatherRepo.fetchCurrent(location);
  final alerts = alertService.evaluate(data);

  for (final alert in alerts) {
    await notificationService.showAlert(alert);
  }
}
```

### 10.3 Notification Channels (Android)

| Channel ID | Name | Importance | Sound |
|------------|------|------------|-------|
| `channel_critical` | Critical Alerts | IMPORTANCE_MAX | Custom alarm tone |
| `channel_warning` | Weather Warnings | IMPORTANCE_HIGH | Default |
| `channel_advisory` | Advisories | IMPORTANCE_DEFAULT | None |
| `channel_info` | General Info | IMPORTANCE_LOW | None |

### 10.4 Critical Alert (iOS)

```dart
const iosDetails = DarwinNotificationDetails(
  categoryIdentifier: 'CRITICAL_ALERT',
  interruptionLevel: InterruptionLevel.critical,
  sound: 'nerv_critical.aiff',  // bundled custom sound
  criticalSoundVolume: 1.0,
);
```

---

## 11. Privacy & Security Requirements

| Req ID | Requirement | Implementation |
|--------|-------------|----------------|
| PRIV-01 | GPS coordinates never sent to any server | Convert lat/lon to ~1km grid cell (Open-Meteo uses lat/lon but only retains it per-request; no user ID sent) |
| PRIV-02 | No analytics SDK | No Firebase Analytics, Mixpanel, or similar |
| PRIV-03 | No advertising SDK | No AdMob, no Meta Audience Network |
| PRIV-04 | No user account required | App functions fully without registration |
| PRIV-05 | All API calls over HTTPS | Enforce `CertificatePinner` on Dio |
| PRIV-06 | Location history not stored remotely | Timeline stored on-device (SQLite) only |
| PRIV-07 | Uninstall clears all data | No remote data deletion needed (no user account) |
| PRIV-08 | Open-Meteo attribution required | Display "Weather data: Open-Meteo.com (CC BY 4.0)" in About screen |

---

## 12. Non-Functional Requirements

### Performance

| Metric | Target |
|--------|--------|
| App cold start to Home screen | < 2 seconds |
| Weather data refresh (cache hit) | < 100ms |
| Weather data refresh (network) | < 1.5 seconds |
| Map tile load | < 500ms per tile |
| Notification delivery (background fetch) | < 5 min latency |
| Scroll frame rate | 60 fps (90/120 on supported devices) |

### Offline Behaviour

| Feature | Offline Behaviour |
|---------|-----------------|
| Home screen | Shows last cached weather with "Last updated X ago" banner |
| Map | Shows cached tiles + last overlay data |
| Timeline | Shows locally stored events |
| Crisis Map | Shows cached pins (read-only) |
| Notifications | Background fetch fails silently; no false alerts |

### Battery

- Background fetch interval: minimum 15 minutes (OS-enforced on iOS)
- Location updates: max once per 15 minutes in background
- Low Power Mode: suspend all background activity; show banner in UI

### App Size

| Target | Value |
|--------|-------|
| iOS IPA (compressed) | < 30 MB |
| Android APK | < 25 MB |
| Android AAB | < 20 MB |

---

## 13. Accessibility Requirements

| ID | Requirement |
|----|-------------|
| ACC-01 | All interactive elements have semantic labels (`Semantics` widget) |
| ACC-02 | Minimum touch target 48×48dp for all tappable elements |
| ACC-03 | WCAG 2.1 AA contrast ratio (4.5:1 for text, 3:1 for UI elements) |
| ACC-04 | No information conveyed by colour alone — always paired with icon or text |
| ACC-05 | VoiceOver / TalkBack: all screens navigable without visual reference |
| ACC-06 | Screen reader layout available (map hidden, linear layout) |
| ACC-07 | Reduce Motion: all animations respect `MediaQuery.of(ctx).disableAnimations` |
| ACC-08 | Font size: respect OS dynamic type; app-level override also available |
| ACC-09 | Colour vision modes selectable per the design system palette (§4.2) |
| ACC-10 | Critical alerts include haptic feedback (pattern-coded by severity) |

---

## 14. Release Milestones

### MVP — v1.0 (Weeks 1–8)

- [ ] Design system implementation (theme, typography, components)
- [ ] Open-Meteo API integration (current + hourly + daily)
- [ ] Home screen (weather cards + alert banners)
- [ ] Weather detail screen
- [ ] Basic push notifications (weather warnings)
- [ ] Settings screen (theme, font, colour vision)
- [ ] Location permission + geocoding

### v1.1 (Weeks 9–12)

- [ ] Map screen with Rain Radar overlay
- [ ] Timeline screen (72-hour log)
- [ ] Air Quality + UV integration
- [ ] Home screen + lock screen widgets
- [ ] Offline mode (stale cache display)

### v1.2 (Weeks 13–16)

- [ ] Crisis Mapping layer (read)
- [ ] Crisis Mapping post/edit (write, Supporters' Club members)
- [ ] Flood API integration
- [ ] Critical Alert full-screen modal
- [ ] Haptic feedback system

### v1.3 (Weeks 17–20)

- [ ] Earthquake EEW simulation (USGS GeoJSON feed)
- [ ] Accessibility audit & screen reader layout
- [ ] Background fetch optimisation
- [ ] Performance profiling & battery testing
- [ ] App Store + Play Store submission

---

## 15. Open Questions & Risks

| # | Question / Risk | Mitigation |
|---|-----------------|-----------|
| R1 | **Open-Meteo commercial terms** — if app adds subscription revenue, free tier no longer applies | Budget for Open-Meteo paid plan ($20+/month) or self-host the API |
| R2 | **API rate limits at scale** — 10,000 calls/day is enough for personal use, not multi-user | Implement server-side caching proxy before public launch |
| R3 | **Background fetch reliability on iOS** — BGAppRefreshTask is not guaranteed | Supplement with silent push notifications from a backend if latency is critical |
| R4 | **Earthquake EEW data** — no global free real-time EEW API exists; USGS is post-event | For a production EEW feature, licence data from a national seismic agency |
| R5 | **Crisis Mapping moderation** — user-submitted data can be inaccurate or malicious | Require account for submission; implement community flagging + admin review queue |
| R6 | **Machine translation quality** — poor translation during crisis can be dangerous | Clearly label machine-translated content; allow manual correction by bilingual members |
| R7 | **Map tile costs** — Mapbox / Google Maps are not free at scale | Use `flutter_map` with OpenStreetMap tiles (free, attribution required) |

---

## Appendix A — Open-Meteo Attribution

As required by CC BY 4.0:

> Weather data provided by **Open-Meteo** (open-meteo.com) under the [CC BY 4.0 licence](https://creativecommons.org/licenses/by/4.0/).  
> Based on data from national weather services: NOAA, ECMWF, DWD, Météo-France, JMA, and others.

Place this attribution in the **About screen** and in the **app's App Store description**.

---

## Appendix B — Design Tokens (Flutter ThemeData)

```dart
ThemeData buildDarkTheme({
  ColourVisionMode visionMode = ColourVisionMode.normal,
  ContrastMode contrast = ContrastMode.normal,
}) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0C10),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFF6B00),
      secondary: const Color(0xFFFF9500),
      surface: const Color(0xFF12151C),
      error: const Color(0xFFFF1744),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFF0F2F8)),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF0F2F8)),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFF0F2F8)),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF8B95B0)),
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF0F2F8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF12151C),
      indicatorColor: const Color(0xFFFF6B0033),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF12151C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2F3E)),
      ),
    ),
  );
}
```

---

*This PRD is a living document. All specifications are subject to revision as development progresses.*  
*Weather data attribution: Open-Meteo.com — CC BY 4.0*
