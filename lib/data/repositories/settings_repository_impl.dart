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
  Future<ColourVisionMode> getColourVisionMode() async {
    final index = await _hiveService.getSetting<int>('colour_vision_mode') ?? 0;
    return ColourVisionMode.values[index];
  }

  @override
  Future<void> setColourVisionMode(ColourVisionMode mode) async {
    await _hiveService.setSetting('colour_vision_mode', mode.index);
  }

  @override
  Future<ContrastMode> getContrastMode() async {
    final index = await _hiveService.getSetting<int>('contrast_mode') ?? 1;
    return ContrastMode.values[index];
  }

  @override
  Future<void> setContrastMode(ContrastMode mode) async {
    await _hiveService.setSetting('contrast_mode', mode.index);
  }

  @override
  Future<TextSizeScale> getTextSizeScale() async {
    final index = await _hiveService.getSetting<int>('text_size_scale') ?? 2;
    return TextSizeScale.values[index];
  }

  @override
  Future<void> setTextSizeScale(TextSizeScale scale) async {
    await _hiveService.setSetting('text_size_scale', scale.index);
  }

  @override
  Future<FontWeightScale> getFontWeightScale() async {
    final index = await _hiveService.getSetting<int>('font_weight_scale') ?? 0;
    return FontWeightScale.values[index];
  }

  @override
  Future<void> setFontWeightScale(FontWeightScale scale) async {
    await _hiveService.setSetting('font_weight_scale', scale.index);
  }

  @override
  Future<List<String>> getSavedLocationIds() async {
    final list = await _hiveService.getSetting<List<dynamic>>('saved_location_ids');
    return list?.cast<String>() ?? [];
  }

  @override
  Future<void> addSavedLocationId(String id) async {
    final ids = await getSavedLocationIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _hiveService.setSetting('saved_location_ids', ids);
    }
  }

  @override
  Future<void> removeSavedLocationId(String id) async {
    final ids = await getSavedLocationIds();
    ids.remove(id);
    await _hiveService.setSetting('saved_location_ids', ids);
  }

  @override
  Future<String?> getSelectedLocationId() async {
    return _hiveService.getSetting<String>('selected_location_id');
  }

  @override
  Future<void> setSelectedLocationId(String? id) async {
    if (id == null) {
      await _hiveService.removeSetting('selected_location_id');
    } else {
      await _hiveService.setSetting('selected_location_id', id);
    }
  }
}
