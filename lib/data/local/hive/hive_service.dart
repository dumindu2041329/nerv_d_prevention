import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/entities/location.dart';

class HiveService {
  static const String weatherCacheBox = 'weather_cache';
  static const String settingsBox = 'settings';

  late Box<dynamic> _weatherCacheBox;
  late Box<dynamic> _settingsBox;

  Future<void> init() async {
    _weatherCacheBox = await Hive.openBox(weatherCacheBox);
    _settingsBox = await Hive.openBox(settingsBox);
  }

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
