import '../../../core/constants/app_colors.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../local/hive/hive_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final HiveService _hiveService;

  SettingsRepositoryImpl({required HiveService hiveService})
    : _hiveService = hiveService;

  @override
  Future<bool> isDarkMode() async {
    return await _hiveService.getSetting<bool>('dark_mode') ?? true;
  }

  @override
  Future<void> setDarkMode(bool value) async {
    await _hiveService.setSetting('dark_mode', value);
  }

  @override
  Future<bool> isNotificationsEnabled() async {
    return await _hiveService.getSetting<bool>('notifications_enabled') ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    await _hiveService.setSetting('notifications_enabled', value);
  }

  @override
  Future<bool> isHazardEnabled(String alertType) async {
    return await _hiveService.getSetting<bool>('hazard_$alertType') ?? true;
  }

  @override
  Future<void> setHazardEnabled(String alertType, bool value) async {
    await _hiveService.setSetting('hazard_$alertType', value);
  }

  @override
  Future<AppLanguage> getLanguage() async {
    final hiveValue = await _hiveService.getSetting<int>('language');
    return AppLanguage.fromHiveValue(hiveValue);
  }

  @override
  Future<void> setLanguage(AppLanguage language) async {
    await _hiveService.setSetting('language', language.hiveValue);
  }

  @override
  Future<ColourVisionMode> getColourVisionMode() async {
    final index = await _hiveService.getSetting<int>('colour_vision_mode') ?? 0;
    return _safeEnum(ColourVisionMode.values, index, ColourVisionMode.values.first);
  }

  @override
  Future<void> setColourVisionMode(ColourVisionMode mode) async {
    await _hiveService.setSetting('colour_vision_mode', mode.index);
  }

  @override
  Future<ContrastMode> getContrastMode() async {
    final index = await _hiveService.getSetting<int>('contrast_mode') ?? 1;
    return _safeEnum(ContrastMode.values, index, ContrastMode.values[1 % ContrastMode.values.length]);
  }

  @override
  Future<void> setContrastMode(ContrastMode mode) async {
    await _hiveService.setSetting('contrast_mode', mode.index);
  }

  @override
  Future<TextSizeScale> getTextSizeScale() async {
    final index = await _hiveService.getSetting<int>('text_size_scale') ?? 2;
    return _safeEnum(TextSizeScale.values, index, TextSizeScale.values[2 % TextSizeScale.values.length]);
  }

  @override
  Future<void> setTextSizeScale(TextSizeScale scale) async {
    await _hiveService.setSetting('text_size_scale', scale.index);
  }

  @override
  Future<FontWeightScale> getFontWeightScale() async {
    final index = await _hiveService.getSetting<int>('font_weight_scale') ?? 0;
    return _safeEnum(FontWeightScale.values, index, FontWeightScale.values.first);
  }

  /// Returns [values][index] when the cached index is in range, otherwise the
  /// supplied [fallback]. Guards against Hive cache corruption or an enum
  /// reorder/refactor throwing RangeError on read.
  static T _safeEnum<T>(List<T> values, int index, T fallback) {
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  @override
  Future<void> setFontWeightScale(FontWeightScale scale) async {
    await _hiveService.setSetting('font_weight_scale', scale.index);
  }
}
