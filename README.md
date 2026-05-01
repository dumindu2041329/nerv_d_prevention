# 🚨 NERV Disaster Prevention App

A Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. It is designed to function as an everyday weather companion and an emergency information hub, delivering real-time weather data, emergency-level alerts, hazard mapping, and community-powered crisis information in a high-contrast dark UI.

## ✨ Features
- 🌦️ **Real-Time Weather & Forecasts**: Hourly and daily forecasts via Open-Meteo API.
- ⚠️ **Emergency Alerts**: Earthquake Early Warning (EEW) with countdowns and critical push notifications.
- 🗺️ **Interactive Layers**: Rain radar, hazard zones, and community crisis mapping using `flutter_map`.
- 🛡️ **Privacy-First**: Zero tracking, zero ads, fully functional offline for cached data.
- ♿ **Accessibility Design**: WCAG 2.1 AA compliance, custom typography (Inter, JetBrains Mono), and specific color vision accessible overrides.

## 🛠️ Tech Stack
- 📱 **Framework**: Flutter (iOS & Android)
- 🎯 **Language**: Dart 3
- 🧠 **State Management**: `flutter_bloc`
- 💉 **Dependency Injection**: `get_it`
- 🛣️ **Routing**: `go_router`
- 🌐 **Network**: `dio`, `dio_cache_interceptor`
- 💾 **Local Storage**: `hive_flutter`, `drift`
- 📍 **Maps & Location**: `flutter_map`, `geolocator`

## 🚀 Getting Started

1. Clone this repository.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to build and launch the app.

For full product requirements and design guidelines, please see the 📄 `NERV_Flutter_App_PRD.md` file.
