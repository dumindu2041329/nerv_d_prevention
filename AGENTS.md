# NERV Disaster Prevention App — Agent Guide

This document provides context for AI agents working on the **nerv_d_prevention** project.

## Project Overview
This project is a Flutter-based disaster prevention and weather alert mobile application inspired by Japan's NERV Disaster Prevention App. It is designed to function as an everyday weather companion and an emergency information hub, delivering real-time weather data, emergency-level alerts, hazard mapping, and community-powered crisis information in a high-contrast dark UI.

## Key Technologies & Dependencies
- **Platform:** Flutter (iOS & Android)
- **Language:** Dart 3 (SDK `^3.11.5`)
- **State Management:** `flutter_bloc`
- **Dependency Injection:** `get_it`
- **Routing:** `go_router`
- **Network & Caching:** `dio`, `dio_cache_interceptor`, `hive_flutter`, `drift` (for timeline/caching)
- **Location & Maps:** `flutter_map`, `latlong2`, `geolocator`, `geocoding`
- **Weather Data:** Open-Meteo API (Free tier, no API key required)

## Design System Principles
- **Clarity over decoration** — Minimalist, tactical operations interface. Every pixel serves information.
- **Urgency hierarchy** — Colour and size signal severity.
- **Night-mode first** — Dark theme is canonical.
- **Privacy-first** — Zero tracking, no ads. Fully functional offline for cached data.
- **Typography:** Inter (primary text) & JetBrains Mono (data readouts, coordinates, countdown timers).

## Architecture & Codebase Guidelines
1. **Follow the BLoC pattern** for state management. Structure should ideally be feature-driven.
2. **UI Implementation**: The UI heavily relies on the application's specific custom color palette and typography (detailed in the PRD). Do not use generic app styling.
3. **Accessibility**: The app is built with a focus on accessibility (WCAG 2.1 AA) and minimum battery impact. Ensure minimum touch targets (48dp) and adequate contrast.
4. **Data Handling & API**: Use the `Open-Meteo API` strictly according to its free tier limits (no API key required). Cache aggressively with `dio_cache_interceptor` and `hive_flutter`/`drift` to maintain offline functionality.
5. **Documentation**: Read the `NERV_Flutter_App_PRD.md` file for full product requirements, design guidelines, map layer specifications, and API endpoints before implementing new features.
