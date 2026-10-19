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

  /// Hourly precipitation RATE (mm/h) triggering an emergency flood warning.
  static const double _floodEmergencyPrecip = 15.0;

  /// Hourly precipitation RATE (mm/h) triggering a flood watch.
  static const double _floodWarningPrecip = 5.0;

  /// Hourly precipitation RATE (mm/h) triggering a rain advisory.
  static const double _rainAdvisoryPrecip = 1.0;

  /// 24h precipitation ACCUMULATION (mm) bands for river / urban flooding.
  /// Kept separate from the rate rules above — monsoon rain routinely
  /// exceeds 15 mm/day without being hazardous, so daily totals must use
  /// daily-scaled thresholds.
  static const double _floodDailyAdvisoryMm = 25;
  static const double _floodDailyWarningMm = 50;
  static const double _floodDailyEmergencyMm = 100;
  static const double _floodDailyCriticalMm = 150;

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

    // Peak hourly rainfall RATE over the current hour + next 6 hours.
    final precipRate = _peakHourlyPrecipRate(data);
    // Today's rainfall ACCUMULATION (mm) — different unit, different rules.
    final precipSum = daily?.precipitationSum ?? current.precipitation;
    final precipProb = daily?.precipitationProbabilityMax ?? 0;
    final windSpeed = daily?.windSpeedMax ?? current.windSpeed;
    final uvIndex = daily?.uvIndexMax ?? current.uvIndex;
    final cloudCover = current.cloudCover;
    final weatherCode = current.weatherCode;
    final now = _providerNow(data);

    final locationLabel = districtName ?? 'Current Location';

    // ── Flood — rate-based flash-flood rules (mm/h) ──
    if (precipRate >= _floodEmergencyPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Flood Warning',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.emergency,
          timestamp: now,
          description:
              'Heavy rainfall (${precipRate.toStringAsFixed(1)} mm/h) detected. '
              'Risk of flash flooding in low-lying areas. Move to higher ground '
              'and monitor DMC instructions.',
        ),
      );
    } else if (precipRate >= _floodWarningPrecip) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Flood Watch',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Significant rainfall (${precipRate.toStringAsFixed(1)} mm/h). '
              'Water levels may rise. Stay alert and prepare to evacuate if '
              'conditions worsen.',
        ),
      );
    } else if (precipRate >= _rainAdvisoryPrecip && precipProb >= 50) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Heavy Rain Advisory',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              'Rainfall of ${precipRate.toStringAsFixed(1)} mm/h with '
              '${precipProb.toStringAsFixed(0)}% probability. Monitor local '
              'water levels.',
        ),
      );
    }

    // ── Flood — accumulation-based river/urban flooding (mm per day) ──
    if (precipSum >= _floodDailyCriticalMm) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Critical Flood Warning',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.critical,
          timestamp: now,
          description:
              '${precipSum.toStringAsFixed(0)} mm of rainfall forecast today. '
              'Severe river and urban flooding likely. Evacuate flood-prone '
              'areas and follow DMC evacuation orders.',
        ),
      );
    } else if (precipSum >= _floodDailyEmergencyMm) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Emergency Flood Warning',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.emergency,
          timestamp: now,
          description:
              '${precipSum.toStringAsFixed(0)} mm of rainfall forecast today. '
              'Major flooding expected. Move to higher ground and avoid '
              'low-lying routes.',
        ),
      );
    } else if (precipSum >= _floodDailyWarningMm) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Flood Watch',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              '${precipSum.toStringAsFixed(0)} mm of rainfall forecast today. '
              'Water levels may rise sharply. Stay alert.',
        ),
      );
    } else if (precipSum >= _floodDailyAdvisoryMm && precipProb >= 60) {
      alerts.add(
        AlertItem(
          title: '$locationLabel — Rainfall Accumulation Advisory',
          alertType: SLAlertType.flood,
          severity: SeverityLevel.advisory,
          timestamp: now,
          description:
              '${precipSum.toStringAsFixed(0)} mm of rainfall forecast today '
              '(${precipProb.toStringAsFixed(0)}% chance). Ground saturation '
              'and localised flooding possible.',
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

    // ── Landslide Watch (for hill-region districts) — driven by today's
    //    rainfall accumulation, not the instantaneous rate. ──
    if (cloudCover >= _landslideCloudCover && precipSum >= _floodDailyAdvisoryMm) {
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
    final now = _providerNow(data);
    final locationLabel = districtName ?? 'Current Location';
    final district = SLDistrict.fromDisplayName(districtName);

    // ── From current conditions ──
    final currentAlerts = deriveAlerts(data, districtName: districtName);
    int id = 0;

    for (final alert in currentAlerts) {
      final fields = _detailFields(
        district: district,
        realLatitude: realLatitude,
        realLongitude: realLongitude,
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
          latitude: fields.latitude,
          longitude: fields.longitude,
        ),
      );
    }

    // ── From daily forecast: add per-day derived alerts ──
    for (int i = 1; i < data.daily.length && i < 5; i++) {
      final day = data.daily[i];
      final dayAlerts = _deriveDailyAlert(day, locationLabel, now, i);

      for (final alert in dayAlerts) {
        final fields = _detailFields(
          district: district,
          realLatitude: realLatitude,
          realLongitude: realLongitude,
        );
        events.add(
          TimelineEvent(
            id: 'derived_${id++}',
            type: alert.alertType.name,
            title: alert.title,
            description: alert.description,
            location: locationLabel,
            severity: alert.severity,
            // Forecast events are anchored to midnight of their day in the
            // provider-local frame (daily values are whole-day aggregates —
            // there is no more precise valid-from).
            time: DateTime(now.year, now.month, now.day)
                .add(Duration(days: i)),
            latitude: fields.latitude,
            longitude: fields.longitude,
          ),
        );
      }
    }

    // Sort chronologically ascending — the timeline rail renders "now"
    // first, then upcoming days. (Descending put the furthest FUTURE
    // forecast above the present: an inverted timeline.)
    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }

  // ── Detail field derivation ─────────────────────────────────────────

  /// Computes the map-placement fields (lat/lng) for the detail screen.
  ///
  /// [realLatitude] / [realLongitude] — when provided, these are the
  /// actual loaded location coordinates and are preferred over the
  /// district center so the cross icon lands on the real spot.
  ///
  /// This deriver deliberately does NOT fabricate seismic-style fields
  /// (max intensity / magnitude / depth / tsunami flag). WeatherAPI data
  /// has no seismic input, and rendering synthesised "MMI 7"/"magnitude"
  /// numbers as authoritative readings in a disaster-prevention app is
  /// misinformation. The detail screen renders '—' when these are absent;
  /// earthquake/tsunami bulletins appear only from a verified upstream
  /// feed (e.g. the GDACS-sourced SOS alert list).
  static _DetailFields _detailFields({
    required SLDistrict? district,
    double? realLatitude,
    double? realLongitude,
  }) {
    // Prefer the actual loaded location over the district center so
    // the cross icon shows up at the real spot on the map.
    final lat = realLatitude ?? district?.center.latitude;
    final lng = realLongitude ?? district?.center.longitude;

    return _DetailFields(latitude: lat, longitude: lng);
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Wall-clock "now" expressed in the location's own clock frame (the
  /// UTC offset captured from the provider). All WeatherAPI timestamps
  /// are parsed as provider-local wall-clock times, so comparisons and
  /// user-facing labels must use the same frame — otherwise a device in
  /// another timezone sees "now" shifted by hours and today/tomorrow
  /// boundaries land on the wrong calendar day.
  static DateTime _providerNow(WeatherData data) =>
      DateTime.now().toUtc().add(data.providerOffset);

  /// Peak hourly precipitation RATE (mm/h) across the current hour plus
  /// the next 6 forecast hours, blended with the instantaneous observed
  /// rate so a ground-truth cloudburst counts even if the hourly grid
  /// smooths it away.
  static double _peakHourlyPrecipRate(WeatherData data) {
    var peak = data.current.precipitation;
    for (final h in data.hourly.take(7)) {
      final mm = h.precipitation;
      if (mm > peak) peak = mm;
    }
    return peak;
  }

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
      // Gusts are only mentioned when the provider actually supplied them
      // (older snapshots cache them as null) — never "Gusts may reach 0".
      final gustLine = day.windGustsMax != null && day.windGustsMax! > 0
          ? ' Gusts may reach ${day.windGustsMax!.toStringAsFixed(0)} km/h.'
          : '';
      alerts.add(
        AlertItem(
          title: '$locationLabel — Strong Wind Forecast ($dayLabel)',
          alertType: SLAlertType.cyclone,
          severity: SeverityLevel.warning,
          timestamp: now,
          description:
              'Winds up to ${day.windSpeedMax.toStringAsFixed(0)} km/h '
              'forecast.$gustLine',
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
  final double? latitude;
  final double? longitude;

  const _DetailFields({
    required this.latitude,
    required this.longitude,
  });
}
