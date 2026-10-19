import '../../core/constants/app_colors.dart';

abstract class SettingsRepository {
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool value);

  Future<bool> isNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);

  /// Per-hazard notification opt-outs, keyed by SLAlertType.name
  /// (flood, landslide, cyclone, lightning, coastalWarning, tsunami)
  /// plus the 'critical' master switch for non-life-threatening tiers.
  /// Defaults to enabled when unset.
  Future<bool> isHazardEnabled(String alertType);
  Future<void> setHazardEnabled(String alertType, bool value);

  Future<AppLanguage> getLanguage();
  Future<void> setLanguage(AppLanguage language);

  Future<ColourVisionMode> getColourVisionMode();
  Future<void> setColourVisionMode(ColourVisionMode mode);

  Future<ContrastMode> getContrastMode();
  Future<void> setContrastMode(ContrastMode mode);

  Future<TextSizeScale> getTextSizeScale();
  Future<void> setTextSizeScale(TextSizeScale scale);

  Future<FontWeightScale> getFontWeightScale();
  Future<void> setFontWeightScale(FontWeightScale scale);
}
