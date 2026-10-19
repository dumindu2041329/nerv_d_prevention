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

  /// Builds a per-location cache key so Island-wide and Local weather never
  /// overwrite each other. Coordinates are rounded to ~1 km (2 decimals) so
  /// tiny GPS jitter still maps to the same bucket.
  static String weatherCacheKey(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(2);
    final lon = longitude.toStringAsFixed(2);
    return 'weather_data|$lat,$lon';
  }

  /// Caches complete weather data including current, hourly, and daily
  /// forecasts, plus a timestamp for staleness checks, keyed by location.
  Future<void> cacheWeatherData(String key, Map<String, dynamic> data) async {
    await _weatherCacheBox.put(key, data);
    await _weatherCacheBox.put(
      '${key}_ts',
      DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic>? getCachedWeatherData(String key) {
    final data = _weatherCacheBox.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  DateTime? getCacheTimestamp(String key) {
    final timestamp = _weatherCacheBox.get('${key}_ts');
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp.toString());
  }

  Future<void> clearWeatherCache() async {
    await _weatherCacheBox.clear();
  }

  Location? getCachedLocation() {
    final data = _weatherCacheBox.get('cached_location');
    if (data == null) return null;
    // Defensive read: older app builds wrote different shapes into this
    // key, and the legacy-cache support contract says a corrupt/foreign
    // entry must degrade to "no cached location" — never throw out of a
    // BLoC event handler and wedge the state machine.
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final id = map['id'];
      final name = map['name'];
      final latitude = map['latitude'];
      final longitude = map['longitude'];
      if (id is! String || name is! String) return null;
      if (latitude is! num || longitude is! num) return null;
      return Location(
        id: id,
        name: name,
        country: map['country'] is String ? map['country'] as String : null,
        admin1: map['admin1'] is String ? map['admin1'] as String : null,
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        isGps: map['isGps'] is bool ? map['isGps'] as bool : false,
      );
    } catch (_) {
      return null;
    }
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
