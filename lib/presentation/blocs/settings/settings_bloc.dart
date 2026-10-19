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
    on<ToggleHazardNotifications>(_onToggleHazardNotifications);
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

    // Per-hazard notification switches: SLAlertType names + the 'critical'
    // master switch (mirrors the Settings screen rows).
    const hazardKeys = [
      'critical',
      'flood',
      'landslide',
      'cyclone',
      'lightning',
      'coastalWarning',
      'tsunami',
    ];
    final hazardNotifications = <String, bool>{
      for (final key in hazardKeys)
        key: await _settingsRepository.isHazardEnabled(key),
    };

    emit(
      SettingsState(
        isDarkMode: isDarkMode,
        language: language,
        colourVisionMode: colourVisionMode,
        contrastMode: contrastMode,
        textSizeScale: textSizeScale,
        fontWeightScale: fontWeightScale,
        notificationsEnabled: notificationsEnabled,
        hazardNotifications: hazardNotifications,
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

    if (!newValue) {
      // Turning off never requires OS permission — persist immediately.
      await _settingsRepository.setNotificationsEnabled(false);
      emit(state.copyWith(notificationsEnabled: false));
      return;
    }

    // Turning on requires the OS to actually grant permission. If the user
    // denies the dialog we must NOT persist an enabled flag the device will
    // silently ignore (every future _plugin.show() would be dropped).
    var granted = false;
    try {
      granted = await _notificationService.requestPermissions();
      if (granted) {
        await _notificationService.showWelcomeNotification();
      }
    } catch (_) {
      granted = false;
    }

    if (!granted) return; // leave the toggle reflecting reality (off)
    await _settingsRepository.setNotificationsEnabled(true);
    emit(state.copyWith(notificationsEnabled: true));
  }

  Future<void> _onToggleHazardNotifications(
    ToggleHazardNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setHazardEnabled(event.key, event.enabled);
    emit(state.copyWith(
      hazardNotifications: {
        ...state.hazardNotifications,
        event.key: event.enabled,
      },
    ));
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
