import '../../domain/entities/weather_data.dart';
import '../../domain/entities/timeline_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_sl_constants.dart';

/// Derives alert objects and timeline events from real WeatherAPI.com
/// [WeatherData]. Used by HomeScreen, TimelineScreen, and MapScreen
/// to replace hardcoded/fake alert content.
class WeatherAlertDeriver {
  WeatherAlertDeriver._();

  // ── Thresholds ──────────────────────────────────────────────────────

  /// Precipitation rate (mm/h) triggering an emergency flood warning.
  static const double _floodEmergencyPrecip = 15.0;

  /// Precipitation rate (mm/h) triggering a flood watch.
  static const double _floodWarningPrecip = 5.0;

  /// Precipitation rate (mm/h) triggering a rain advisory.
  static const double _rainAdvisoryPrecip = 1.0;

  /// Wind speed (km/h) triggering a cyclone advisory.
  static const double _cycloneEmergencyWind = 50.0;

  /// Wind speed (km/h) triggering a strong wind alert.
  static const double _cycloneWarningWind = 30.0;

  /// UV index triggering a UV hazard advisory.
  static const double _uvAdvisoryThreshold = 8.0;

  /// Cloud cover (%) combined with precipitation for landslide risk.
  static const double _landslideCloudCover = 90.0;

  // ── Public API ──────────────────────────────────────────────────────

  /// Derives a list of [AlertItem] cards for the HomeScreen alert
  /// section, ordered by severity (most severe first).
  static List<AlertItem> deriveAlerts(
    WeatherData data, {
    String? districtName,
  }) {
    final alerts = <AlertItem>[];
    final current = data.current;
    final daily = data.daily.isNotEmpty ? data.daily.first : null;

    final precip = daily?.precipitationSum ?? current.precipitation;
    final precipProb = daily?.precipitationProbabilityMax ?? 0;
    final windSpeed = daily?.windSpeedMax ?? current.windSpeed;
    final uvIndex = daily?.uvIndexMax ?? current.uvIndex;
    final cloudCover = current.cloudCover;
    final weatherCode = current.weatherCode;
    final now = DateTime.now();

    final locationLabel = districtName ?? 'Current Location';

    // ── Flood / Heavy Rain ──
    if (precip >= _floodEmergencyPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Flood Warning',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.emergency,
          timestamp: now,
          description:
              'Heavy rainfall (${precip.toStringAsFixed(1)} mm/h) detected. '
              'Risk of flash flooding in low-lying areas. Move to higher ground '
              'and monitor DMC instructions.',
        ),
      );
    } else if (precip >= _floodWarningPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Flood Watch',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Significant rainfall (${precip.toStringAsFixed(1)} mm/h). '
              'Water levels may rise. Stay alert and prepare to evacuate if '
              'conditions worsen.',
        ),
      );
    } else if (precip >= _rainAdvisoryPrecip && precipProb >= 50) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Heavy Rain Advisory',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              'Rainfall of ${precip.toStringAsFixed(1)} mm/h with '
              '${precipProb.toStringAsFixed(0)}% probability. Monitor local '
              'water levels.',
        ),
      );
    }

    // ── Cyclone / Strong Wind ──
    if (windSpeed >= _cycloneEmergencyWind) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Cyclone Advisory',
          alertType: SLAlertType.cyclone,
          severity: SeverityLevel.emergency,
          timestamp: now,
          description:
              'Wind speeds reaching ${windSpeed.toStringAsFixed(0)} km/h. '
              'Seek shelter immediately. Fishermen advised not to venture into '
              'the sea.',
        ),
      );
    } else if (windSpeed >= _cycloneWarningWind) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Strong Wind Alert',
          alertType: SLAlertType.cyclone,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Sustained winds of ${windSpeed.toStringAsFixed(0)} km/h. '
              'Secure loose objects. Exercise caution near trees and power lines.',
        ),
      );
    }

    // ── Lightning / Thunderstorm ──
    if (_isThunderstorm(weatherCode)) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Lightning Alert',
          alertType: SLAlertType.lightning,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Thunderstorm activity detected. Avoid open areas, tall trees, '
              'and bodies of water. Seek shelter in a sturdy building.',
        ),
      );
    }

    // ── Coastal Warning ──
    if (windSpeed >= _cycloneWarningWind && precipProb >= 40) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Coastal Warning',
          alertType: SLAlertType.coastalWarning,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Strong winds and precipitation near the coast. Wave heights may '
              'be elevated. Exercise caution near shoreline areas.',
        ),
      );
    }

    // ── UV Hazard ──
    if (uvIndex >= _uvAdvisoryThreshold) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — UV Hazard Advisory',
          alertType: SLAlertType.coastalWarning,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              'UV Index of ${uvIndex.toStringAsFixed(1)} — Very High. '
              'Limit sun exposure between 10 AM and 4 PM. Wear sunscreen, '
              'a hat, and protective clothing.',
        ),
      );
    }

    // ── Landslide Watch (for hill-region districts) ──
    if (cloudCover >= _landslideCloudCover && precip >= _rainAdvisoryPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Landslide Watch',
          alertType: SLAlertType.landslide,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Prolonged rainfall on saturated slopes. Risk of landslides. '
              'Residents on steep terrain should monitor conditions and be '
              'ready to relocate.',
        ),
      );
    }

    // ── If nothing triggered, show an "all clear" info card ──
    if (alerts.isEmpty) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — All Clear',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.calm,
          timestamp: now,
          description:
              'No hazardous weather conditions detected. Temperature is '
              '${current.temperature.toStringAsFixed(1)}°C, humidity '
              '${current.humidity.toStringAsFixed(0)}%. Enjoy the calm weather.',
        ),
      );
    }

    // Sort by severity (most severe first)
    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  /// Derives a list of [TimelineEvent] objects from [WeatherData] for
  /// the TimelineScreen, drawing from current conditions and daily
  /// forecast entries.
  ///
  /// [realLatitude] / [realLongitude] are the actual loaded location
  /// coordinates (GPS or Island-wide center). When supplied they are
  /// used for the event's `latitude`/`longitude` so the cross icon on
  /// the detail map lands on the real spot — not the district center.
  static List<TimelineEvent> deriveTimelineEvents(
    WeatherData data, {
    String? districtName,
    double? realLatitude,
    double? realLongitude,
  }) {
    final events = <TimelineEvent>[];
    final now = DateTime.now();
    final locationLabel = districtName ?? 'Current Location';
    final district = SLDistrict.fromDisplayName(districtName);

    // ── From current conditions ──
    final currentAlerts = deriveAlerts(data, districtName: districtName);
    int id = 0;

    // Earthquake context — if any current alert qualifies as a seismic
    // event we remember it so we can attach a tsunami bulletin to it.
    // Tsunami is NEVER shown on its own.
    bool hasEarthquakeContext = currentAlerts.any(
      (a) => a.alertType == SLAlertType.earthquake,
    );

    for (final alert in currentAlerts) {
      final fields = _detailFields(
        alert: alert,
        current: data.current,
        district: district,
        realLatitude: realLatitude,
        realLongitude: realLongitude,
        isDaily: false,
        hasEarthquakeContext: hasEarthquakeContext,
      );
      events.add(
        TimelineEvent(
          id: 'derived_${id++}',
          type: alert.alertType.name,
          title: alert.title,
          description: alert.description,
          location: locationLabel,
          severity: alert.severity,
          time: now,
          maxIntensity: fields.maxIntensity,
          magnitude: fields.magnitude,
          magnitudeLabel: fields.magnitudeLabel,
          depthKm: fields.depthKm,
          depthLabel: fields.depthLabel,
          tsunamiFlag: fields.tsunamiFlag,
          latitude: fields.latitude,
          longitude: fields.longitude,
        ),
      );
    }

    // Attach a tsunami bulletin for the most recent earthquake event.
    // Only generated when there is real earthquake context.
    if (hasEarthquakeContext) {
      final eq = currentAlerts.firstWhere(
        (a) => a.alertType == SLAlertType.earthquake,
      );
      events.add(
        TimelineEvent(
          id: 'derived_${id++}',
          type: SLAlertType.tsunami.name,
          title: '$locationLabel — Tsunami Bulletin',
          description:
              'Tsunami advisory issued following the seismic event near '
              '${eq.title.split('—').last.trim()}. Coastal residents should '
              'move to higher ground and follow DMC instructions.',
          location: locationLabel,
          severity: SeverityLevel.critical,
          time: now,
          maxIntensity: 7,
          magnitude: null,
          magnitudeLabel: 'M',
          depthKm: 10.0,
          depthLabel: 'Open ocean',
          tsunamiFlag: true,
          latitude: realLatitude ?? district?.center.latitude,
          longitude: realLongitude ?? district?.center.longitude,
        ),
      );
    }

    // ── From daily forecast: add per-day derived alerts ──
    for (int i = 1; i < data.daily.length && i < 5; i++) {
      final day = data.daily[i];
      final dayAlerts = _deriveDailyAlert(day, locationLabel, now, i);

      for (final alert in dayAlerts) {
        final fields = _detailFields(
          alert: alert,
          current: day,
          district: district,
          realLatitude: realLatitude,
          realLongitude: realLongitude,
          isDaily: true,
          hasEarthquakeContext: false,
        );
        events.add(
          TimelineEvent(
            id: 'derived_${id++}',
            type: alert.alertType.name,
            title: alert.title,
            description: alert.description,
            location: locationLabel,
            severity: alert.severity,
            time: now.add(Duration(days: i)),
            maxIntensity: fields.maxIntensity,
            magnitude: fields.magnitude,
            magnitudeLabel: fields.magnitudeLabel,
            depthKm: fields.depthKm,
            depthLabel: fields.depthLabel,
            tsunamiFlag: fields.tsunamiFlag,
            latitude: fields.latitude,
            longitude: fields.longitude,
          ),
        );
      }
    }

    // Sort by time descending (newest first)
    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }

  // ── Detail field derivation ─────────────────────────────────────────

  /// Computes the detail-screen fields (intensity, magnitude, depth,
  /// tsunami flag, lat/lng) from the underlying weather data and the
  /// alert that fired.
  ///
  /// [realLatitude] / [realLongitude] — when provided, these are the
  /// actual loaded location coordinates and are preferred over the
  /// district center so the cross icon lands on the real spot.
  ///
  /// [hasEarthquakeContext] — tsunami flag is only set when there is a
  /// concurrent earthquake event. Tsunami is never shown on its own.
  static _DetailFields _detailFields({
    required AlertItem alert,
    required dynamic current, // CurrentWeather or DailyWeather
    required SLDistrict? district,
    required bool isDaily,
    double? realLatitude,
    double? realLongitude,
    bool hasEarthquakeContext = false,
  }) {
    final precip = _readPrecip(current, isDaily);
    final wind = _readWind(current, isDaily);
    final isThunder = _isThunderstorm(_readWeatherCode(current, isDaily));

    // Prefer the actual loaded location over the district center so
    // the cross icon shows up at the real spot on the map.
    final lat = realLatitude ?? district?.center.latitude;
    final lng = realLongitude ?? district?.center.longitude;

    // Tsunami flag — only true for actual tsunami bulletins that are
    // attached to a real earthquake event. A standalone tsunami alert
    // (without earthquake context) is suppressed.
    final tsunamiFlag = alert.alertType == SLAlertType.tsunami &&
        hasEarthquakeContext;

    // Intensity: 1–7 scale (JMA-style). Higher = more severe.
    // Driven by the actual precip / wind value that triggered the alert,
    // not by the severity enum.
    final intensity = _intensityFromConditions(
      alertType: alert.alertType,
      precipMm: precip,
      windKph: wind,
      isThunder: isThunder,
    );

    // Magnitude: a number whose unit depends on the event type.
    final mag = _magnitudeFromConditions(
      alertType: alert.alertType,
      precipMm: precip,
      windKph: wind,
    );
    final magLabel = _magnitudeLabelFor(alert.alertType);

    // Depth: a physical depth in km appropriate to the event type.
    final depth = _depthForAlertType(alert.alertType);

    return _DetailFields(
      maxIntensity: intensity,
      magnitude: mag,
      magnitudeLabel: magLabel,
      depthKm: depth.km,
      depthLabel: depth.label,
      tsunamiFlag: tsunamiFlag,
      latitude: lat,
      longitude: lng,
    );
  }

  static int? _intensityFromConditions({
    required SLAlertType alertType,
    required double precipMm,
    required double windKph,
    required bool isThunder,
  }) {
    switch (alertType) {
      case SLAlertType.flood:
        // Map precipitation (mm) onto a 1–7 intensity scale.
        if (precipMm >= 50) return 7;
        if (precipMm >= 30) return 6;
        if (precipMm >= 15) return 5;
        if (precipMm >= 5) return 4;
        if (precipMm >= 1) return 3;
        return 2;
      case SLAlertType.cyclone:
        // Saffir–Simpson–style mapping by sustained wind (km/h).
        if (windKph >= 252) return 7; // Cat 5
        if (windKph >= 178) return 6; // Cat 4
        if (windKph >= 154) return 5; // Cat 3
        if (windKph >= 118) return 4; // Cat 2
        if (windKph >= 88) return 3; // Cat 1
        if (windKph >= 62) return 2; // TS
        return 1;
      case SLAlertType.lightning:
        return isThunder ? 4 : 3;
      case SLAlertType.landslide:
        return precipMm >= 50 ? 6 : (precipMm >= 15 ? 5 : 4);
      case SLAlertType.coastalWarning:
        return windKph >= 88 ? 4 : 3;
      case SLAlertType.tsunami:
        return 7;
      case SLAlertType.earthquake:
        return 6;
    }
  }

  static double? _magnitudeFromConditions({
    required SLAlertType alertType,
    required double precipMm,
    required double windKph,
  }) {
    switch (alertType) {
      case SLAlertType.flood:
      case SLAlertType.landslide:
        // Rainfall magnitude: total millimetres.
        return precipMm;
      case SLAlertType.cyclone:
        // Wind magnitude: km/h divided by 10 → 1-decimal "Richter-like" number.
        if (windKph <= 0) return null;
        return double.parse((windKph / 10).toStringAsFixed(1));
      case SLAlertType.lightning:
        // Storm intensity proxy: 0–10 from thunderstorm code presence.
        return 0;
      case SLAlertType.coastalWarning:
        return windKph > 0
            ? double.parse((windKph / 10).toStringAsFixed(1))
            : null;
      case SLAlertType.tsunami:
        return null; // Tsunami magnitude requires a dedicated scale.
      case SLAlertType.earthquake:
        return null; // Earthquake magnitude requires a seismic source.
    }
  }

  static String? _magnitudeLabelFor(SLAlertType alertType) {
    switch (alertType) {
      case SLAlertType.flood:
      case SLAlertType.landslide:
        return 'mm';
      case SLAlertType.cyclone:
      case SLAlertType.coastalWarning:
      case SLAlertType.earthquake:
        return 'M';
      case SLAlertType.lightning:
        return 'idx';
      case SLAlertType.tsunami:
        return null;
    }
  }

  static _DepthHint _depthForAlertType(SLAlertType type) {
    switch (type) {
      case SLAlertType.flood:
      case SLAlertType.landslide:
        return _DepthHint(0.0, 'Surface');
      case SLAlertType.cyclone:
        return _DepthHint(1.0, 'Atmospheric boundary layer');
      case SLAlertType.lightning:
        return _DepthHint(4.0, 'Cloud-to-ground');
      case SLAlertType.coastalWarning:
        return _DepthHint(0.0, 'Coastal');
      case SLAlertType.tsunami:
        return _DepthHint(10.0, 'Open ocean');
      case SLAlertType.earthquake:
        return _DepthHint(10.0, 'Crustal');
    }
  }

  // ── Typed reads from CurrentWeather | DailyWeather ──────────────────

  static double _readPrecip(dynamic w, bool isDaily) {
    if (w == null) return 0;
    if (isDaily) {
      final d = w as DailyWeather;
      return d.precipitationSum;
    }
    final c = w as CurrentWeather;
    return c.precipitation;
  }

  static double _readWind(dynamic w, bool isDaily) {
    if (w == null) return 0;
    if (isDaily) {
      final d = w as DailyWeather;
      return d.windSpeedMax;
    }
    final c = w as CurrentWeather;
    return c.windSpeed;
  }

  static int _readWeatherCode(dynamic w, bool isDaily) {
    if (w == null) return 1000;
    if (isDaily) {
      return (w as DailyWeather).weatherCode;
    }
    return (w as CurrentWeather).weatherCode;
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Returns true when [weatherCode] indicates a thunderstorm. Uses the
  /// WeatherAPI.com condition code range (1000–1282).
  /// Thunder-related codes: 1087 (thundery outbreaks possible),
  /// 1273/1276 (rain + thunder), 1279/1282 (snow + thunder).
  static bool _isThunderstorm(int weatherCode) {
    if (weatherCode == 1087) return true;
    if (weatherCode >= 1273 && weatherCode <= 1282) {
      // 1273 patchy light rain w/ thunder
      // 1276 moderate or heavy rain w/ thunder
      // 1279 patchy light snow w/ thunder
      // 1282 moderate or heavy snow w/ thunder
      return true;
    }
    return false;
  }

  static List<AlertItem> _deriveDailyAlert(
    DailyWeather day,
    String locationLabel,
    DateTime now,
    int dayOffset,
  ) {
    final alerts = <AlertItem>[];
    final dayLabel = dayOffset == 1 ? 'Tomorrow' : 'Day $dayOffset';

    if (day.precipitationSum >= _floodWarningPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Heavy Rain Forecast ($dayLabel)',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Forecast: ${day.precipitationSum.toStringAsFixed(1)} mm rainfall '
              'with ${day.precipitationProbabilityMax.toStringAsFixed(0)}% '
              'probability. Prepare for possible flooding.',
        ),
      );
    }

    if (day.windSpeedMax >= _cycloneWarningWind) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Strong Wind Forecast ($dayLabel)',
          alertType: SLAlertType.cyclone,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Winds up to ${day.windSpeedMax.toStringAsFixed(0)} km/h '
              'forecast. Gusts may reach '
              '${day.windGustsMax.toStringAsFixed(0)} km/h.',
        ),
      );
    }

    if (_isThunderstorm(day.weatherCode)) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Thunderstorm Risk ($dayLabel)',
          alertType: SLAlertType.lightning,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              'Thunderstorms possible. Keep indoors and avoid open areas.',
        ),
      );
    }

    if (day.uvIndexMax >= _uvAdvisoryThreshold) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — High UV Forecast ($dayLabel)',
          alertType: SLAlertType.coastalWarning,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              'UV Index of ${day.uvIndexMax.toStringAsFixed(1)} forecast. '
              'Take sun protection measures.',
        ),
      );
    }

    return alerts;
  }
}

/// A lightweight alert card item for the HomeScreen alert section.
/// Mirrors the fields previously hardcoded in the UI.
class AlertItem {
  final String title;
  final SLAlertType alertType;
  final SeverityLevel severity;
  final DateTime timestamp;
  final String description;

  const AlertItem({
    required this.title,
    required this.alertType,
    required this.severity,
    required this.timestamp,
    required this.description,
  });
}

/// Internal carrier for the detail-screen fields computed by
/// [_detailFields]. Spread into [TimelineEvent] by name.
class _DetailFields {
  final int? maxIntensity;
  final double? magnitude;
  final String? magnitudeLabel;
  final double? depthKm;
  final String? depthLabel;
  final bool tsunamiFlag;
  final double? latitude;
  final double? longitude;

  const _DetailFields({
    required this.maxIntensity,
    required this.magnitude,
    required this.magnitudeLabel,
    required this.depthKm,
    required this.depthLabel,
    required this.tsunamiFlag,
    required this.latitude,
    required this.longitude,
  });
}

class _DepthHint {
  final double? km;
  final String label;
  const _DepthHint(this.km, this.label);
}
