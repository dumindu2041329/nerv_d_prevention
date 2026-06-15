# MapTiler Commercial Tile Migration Plan

**Status:** ✅ Implemented | **Date:** 2026-05-27

## Architecture

Map tiles are proxied through the Shelf backend, matching the existing pattern. The API key stays server-side in [`backend/.env`](backend/.env).

```
flutter_map → http://localhost:8080/tiles/{z}/{x}/{y} → api.maptiler.com (with key)
```

This avoids embedding the MapTiler key in the Flutter APK and keeps all third-party keys in one place.

## Files Changed

| File | Change |
|---|---|
| [`backend/.env`](backend/.env) | Added `MAPTILER_API_KEY` |
| [`backend/lib/server.dart`](backend/lib/server.dart) | Added `/tiles/<z>/<x>/<y>` proxy route; reads `mapTilerKey` from `.env` |
| [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) | Added `mapTileProxyUrl` pointing to backend proxy |
| [`lib/presentation/screens/map/map_screen.dart`](lib/presentation/screens/map/map_screen.dart) | Replaced CartoDB tile URL with MapTiler proxy URL; added `RichAttributionWidget` |

## Provider: MapTiler

- **Style:** Streets Dark v2 (raster PNG)
- **Pricing:** 100K tiles/month free; $20/mo for 200K
- **Key restriction:** Not needed — key is server-side only in the backend proxy

## How to Start

1. Ensure `backend/.env` has your valid `MAPTILER_API_KEY`
2. Start the backend: `cd backend && dart run lib/server.dart`
3. Start the Flutter app: `flutter run`
4. Map tiles will load via `localhost:8080/tiles/{z}/{x}/{y}`