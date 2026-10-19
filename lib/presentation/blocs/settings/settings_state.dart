part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final AppLanguage language;
  final ColourVisionMode colourVisionMode;
  final ContrastMode contrastMode;
  final TextSizeScale textSizeScale;
  final FontWeightScale fontWeightScale;
  final bool notificationsEnabled;

  /// Per-hazard notification opt-outs keyed by SLAlertType.name plus the
  /// 'critical' master switch. Missing keys are treated as enabled.
  /// Critical/Emergency deliveries ignore these switches by design.
  final Map<String, bool> hazardNotifications;
  final bool isLoaded;

  const SettingsState({
    this.isDarkMode = true,
    this.language = AppLanguage.english,
    this.colourVisionMode = ColourVisionMode.normal,
    this.contrastMode = ContrastMode.normal,
    this.textSizeScale = TextSizeScale.normal,
    this.fontWeightScale = FontWeightScale.normal,
    this.notificationsEnabled = true,
    this.hazardNotifications = const {},
    this.isLoaded = false,
  });

  /// Read a hazard toggle with the shipped default (enabled) when unset.
  bool isHazardEnabled(String key) => hazardNotifications[key] ?? true;

  @override
  List<Object?> get props => [
    isDarkMode,
    language,
    colourVisionMode,
    contrastMode,
    textSizeScale,
    fontWeightScale,
    notificationsEnabled,
    hazardNotifications,
    isLoaded,
  ];

  SettingsState copyWith({
    bool? isDarkMode,
    AppLanguage? language,
    ColourVisionMode? colourVisionMode,
    ContrastMode? contrastMode,
    TextSizeScale? textSizeScale,
    FontWeightScale? fontWeightScale,
    bool? notificationsEnabled,
    Map<String, bool>? hazardNotifications,
    bool? isLoaded,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      colourVisionMode: colourVisionMode ?? this.colourVisionMode,
      contrastMode: contrastMode ?? this.contrastMode,
      textSizeScale: textSizeScale ?? this.textSizeScale,
      fontWeightScale: fontWeightScale ?? this.fontWeightScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hazardNotifications: hazardNotifications ?? this.hazardNotifications,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
