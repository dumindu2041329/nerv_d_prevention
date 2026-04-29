import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<SetColourVisionMode>(_onSetColourVisionMode);
    on<SetContrastMode>(_onSetContrastMode);
    on<SetTextSizeScale>(_onSetTextSizeScale);
    on<SetFontWeightScale>(_onSetFontWeightScale);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final isDarkMode = await _settingsRepository.isDarkMode();
    final colourVisionMode = await _settingsRepository.getColourVisionMode();
    final contrastMode = await _settingsRepository.getContrastMode();
    final textSizeScale = await _settingsRepository.getTextSizeScale();
    final fontWeightScale = await _settingsRepository.getFontWeightScale();

    emit(SettingsState(
      isDarkMode: isDarkMode,
      colourVisionMode: colourVisionMode,
      contrastMode: contrastMode,
      textSizeScale: textSizeScale,
      fontWeightScale: fontWeightScale,
      isLoaded: true,
    ));
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.isDarkMode;
    await _settingsRepository.setDarkMode(newValue);
    emit(state.copyWith(isDarkMode: newValue));
  }

  Future<void> _onSetColourVisionMode(
    SetColourVisionMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setColourVisionMode(event.mode);
    emit(state.copyWith(colourVisionMode: event.mode));
  }

  Future<void> _onSetContrastMode(
    SetContrastMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setContrastMode(event.mode);
    emit(state.copyWith(contrastMode: event.mode));
  }

  Future<void> _onSetTextSizeScale(
    SetTextSizeScale event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setTextSizeScale(event.scale);
    emit(state.copyWith(textSizeScale: event.scale));
  }

  Future<void> _onSetFontWeightScale(
    SetFontWeightScale event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setFontWeightScale(event.scale);
    emit(state.copyWith(fontWeightScale: event.scale));
  }
}
