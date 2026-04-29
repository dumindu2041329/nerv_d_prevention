import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String weatherCacheBox = 'weather_cache';
  static const String settingsBox = 'settings';

  late Box<dynamic> _weatherCacheBox;
  late Box<dynamic> _settingsBox;

  Future<void> init() async {
    _weatherCacheBox = await Hive.openBox(weatherCacheBox);
    _settingsBox = await Hive.openBox(settingsBox);
  }

  Future<void> cacheWeatherData(Map<String, dynamic> data) async {
    await _weatherCacheBox.put('weather_data', data);
    await _weatherCacheBox.put('cache_timestamp', DateTime.now().toIso8601String());
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

  Future<T?> getSetting<T>(String key) async {
    return _settingsBox.get(key) as T?;
  }

  Future<void> setSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> removeSetting(String key) async {
    await _settingsBox.delete(key);
  }
}
