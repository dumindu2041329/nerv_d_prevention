import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/alert.dart';
import '../../../domain/entities/location.dart';

class HiveService {
  static const String weatherCacheBox = 'weather_cache';
  static const String settingsBox = 'settings';
  static const String alertsCacheBox = 'alerts_cache';

  late Box<dynamic> _weatherCacheBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _alertsCacheBox;

  Future<void> init() async {
    _weatherCacheBox = await Hive.openBox(weatherCacheBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _alertsCacheBox = await Hive.openBox(alertsCacheBox);
  }

  // ── SOS / Disaster alert cache ─────────────────────────────────────

  /// Persists the full list of [Alert]s plus a freshness timestamp.
  /// Stored as a JSON string so older cache versions remain readable.
  Future<void> cacheSosAlerts(List<Alert> alerts) async {
    final encoded = jsonEncode(alerts.map(_alertToMap).toList());
    await _alertsCacheBox.put('sos_alerts', encoded);
    await _alertsCacheBox.put(
      'sos_alerts_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns the cached SOS alerts or `null` if none exist.
  List<Alert>? getCachedSosAlerts() {
    final raw = _alertsCacheBox.get('sos_alerts');
    if (raw is! String) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(_alertFromMap)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  DateTime? getSosAlertsCacheTimestamp() {
    final raw = _alertsCacheBox.get('sos_alerts_timestamp');
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic> _alertToMap(Alert a) => {
        'id': a.id,
        'type': a.type,
        'headline': a.headline,
        'description': a.description,
        'severity': a.severity.name,
        'issuedTime': a.issuedTime.toIso8601String(),
        'expiryTime': a.expiryTime?.toIso8601String(),
        'location': a.location,
        'metadata': a.metadata,
      };

  Alert _alertFromMap(Map<String, dynamic> m) => Alert(
        id: m['id'] as String,
        type: m['type'] as String,
        headline: m['headline'] as String,
        description: m['description'] as String,
        severity: SeverityLevel.values.firstWhere(
          (s) => s.name == m['severity'],
          orElse: () => SeverityLevel.info,
        ),
        issuedTime: DateTime.parse(m['issuedTime'] as String),
        expiryTime: m['expiryTime'] is String
            ? DateTime.tryParse(m['expiryTime'] as String)
            : null,
        location: m['location'] as String? ?? '',
        metadata: m['metadata'] is Map
            ? Map<String, dynamic>.from(m['metadata'] as Map)
            : null,
      );

  /// Caches complete weather data including current, hourly, and daily
  /// forecasts, plus a timestamp for staleness checks.
  Future<void> cacheWeatherData(Map<String, dynamic> data) async {
    await _weatherCacheBox.put('weather_data', data);
    await _weatherCacheBox.put(
      'cache_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic>? getCachedWeatherData() {
    final data = _weatherCacheBox.get('weather_data');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  DateTime? getCacheTimestamp() {
    final timestamp = _weatherCacheBox.get('cache_timestamp');
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  Future<void> clearWeatherCache() async {
    await _weatherCacheBox.clear();
  }

  Location? getCachedLocation() {
    final data = _weatherCacheBox.get('cached_location');
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data);
    return Location(
      id: map['id'] as String,
      name: map['name'] as String,
      country: map['country'] as String?,
      admin1: map['admin1'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isGps: map['isGps'] as bool? ?? false,
    );
  }

  Future<void> cacheLocation(Location location) async {
    await _weatherCacheBox.put('cached_location', {
      'id': location.id,
      'name': location.name,
      'country': location.country,
      'admin1': location.admin1,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'isGps': location.isGps,
    });
  }

  // ── Settings (generic key-value) ──────────────────────────────────

  Future<T?> getSetting<T>(String key) async {
    return _settingsBox.get(key) as T?;
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> removeSetting(String key) async {
    await _settingsBox.delete(key);
  }

  Future<void> cacheSettings(Map<String, dynamic> data) async {
    await _settingsBox.putAll(data);
  }

  Map<String, dynamic>? getSettings() {
    final keys = _settingsBox.keys;
    if (keys.isEmpty) return null;
    final map = <String, dynamic>{};
    for (final key in keys) {
      map[key.toString()] = _settingsBox.get(key);
    }
    return map;
  }
}
