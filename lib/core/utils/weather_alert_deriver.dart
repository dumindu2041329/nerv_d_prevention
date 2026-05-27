import '../../domain/entities/weather_data.dart';
import '../../domain/entities/timeline_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_sl_constants.dart';

/// Derives alert objects and timeline events from real AccuWeather
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
  static List<TimelineEvent> deriveTimelineEvents(
    WeatherData data, {
    String? districtName,
  }) {
    final events = <TimelineEvent>[];
    final now = DateTime.now();
    final locationLabel = districtName ?? 'Current Location';

    // ── From current conditions ──
    final currentAlerts = deriveAlerts(data, districtName: districtName);
    int id = 0;

    for (final alert in currentAlerts) {
      events.add(
        TimelineEvent(
          id: 'derived_${id++}',
          type: alert.alertType.name,
          title: alert.title,
          description: alert.description,
          location: locationLabel,
          severity: alert.severity,
          time: now,
        ),
      );
    }

    // ── From daily forecast: add per-day derived alerts ──
    for (int i = 1; i < data.daily.length && i < 5; i++) {
      final day = data.daily[i];
      final dayAlerts = _deriveDailyAlert(day, locationLabel, now, i);

      for (final alert in dayAlerts) {
        events.add(
          TimelineEvent(
            id: 'derived_${id++}',
            type: alert.alertType.name,
            title: alert.title,
            description: alert.description,
            location: locationLabel,
            severity: alert.severity,
            time: now.add(Duration(days: i)),
          ),
        );
      }
    }

    // Sort by time descending (newest first)
    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  static bool _isThunderstorm(int weatherCode) {
    // AccuWeather codes for thunderstorm: 14-18, 40-44
    return (weatherCode >= 14 && weatherCode <= 18) ||
        (weatherCode >= 40 && weatherCode <= 44);
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
