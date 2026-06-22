import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final LocalNotificationService _notificationService;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required LocalNotificationService notificationService,
  }) : _settingsRepository = settingsRepository,
       _notificationService = notificationService,
       super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleNotifications>(_onToggleNotifications);
    on<SetLanguage>(_onSetLanguage);
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
    final language = await _settingsRepository.getLanguage();
    final colourVisionMode = await _settingsRepository.getColourVisionMode();
    final contrastMode = await _settingsRepository.getContrastMode();
    final textSizeScale = await _settingsRepository.getTextSizeScale();
    final fontWeightScale = await _settingsRepository.getFontWeightScale();
    final notificationsEnabled =
        await _settingsRepository.isNotificationsEnabled();

    emit(
      SettingsState(
        isDarkMode: isDarkMode,
        language: language,
        colourVisionMode: colourVisionMode,
        contrastMode: contrastMode,
        textSizeScale: textSizeScale,
        fontWeightScale: fontWeightScale,
        notificationsEnabled: notificationsEnabled,
        isLoaded: true,
      ),
    );
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.isDarkMode;
    await _settingsRepository.setDarkMode(newValue);
    emit(state.copyWith(isDarkMode: newValue));
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.notificationsEnabled;
    await _settingsRepository.setNotificationsEnabled(newValue);

    // When the user turns notifications on, ask the OS for permission
    // so future Critical/Emergency alerts can actually surface on the
    // device. Failures are non-fatal — the in-app toggle stays on and
    // the next settings refresh can retry.
    if (newValue) {
      try {
        await _notificationService.requestPermissions();
        // Fire a real on-device confirmation toast so the user can
        // verify the notification pipeline is actually wired up.
        await _notificationService.showWelcomeNotification();
      } catch (_) {
        // Permission denial shouldn't crash the bloc; the in-app
        // toggle reflects the user's intent regardless of OS state.
      }
    }

    emit(state.copyWith(notificationsEnabled: newValue));
  }

  Future<void> _onSetLanguage(
    SetLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setLanguage(event.language);
    emit(state.copyWith(language: event.language));
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
