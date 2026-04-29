import '../../core/constants/app_colors.dart';

abstract class SettingsRepository {
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool value);

  Future<ColourVisionMode> getColourVisionMode();
  Future<void> setColourVisionMode(ColourVisionMode mode);

  Future<ContrastMode> getContrastMode();
  Future<void> setContrastMode(ContrastMode mode);

  Future<TextSizeScale> getTextSizeScale();
  Future<void> setTextSizeScale(TextSizeScale scale);

  Future<FontWeightScale> getFontWeightScale();
  Future<void> setFontWeightScale(FontWeightScale scale);

  Future<List<String>> getSavedLocationIds();
  Future<void> addSavedLocationId(String id);
  Future<void> removeSavedLocationId(String id);

  Future<String?> getSelectedLocationId();
  Future<void> setSelectedLocationId(String? id);
}
