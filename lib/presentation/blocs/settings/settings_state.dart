part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final AppLanguage language;
  final ColourVisionMode colourVisionMode;
  final ContrastMode contrastMode;
  final TextSizeScale textSizeScale;
  final FontWeightScale fontWeightScale;
  final bool notificationsEnabled;
  final bool isLoaded;

  const SettingsState({
    this.isDarkMode = true,
    this.language = AppLanguage.english,
    this.colourVisionMode = ColourVisionMode.normal,
    this.contrastMode = ContrastMode.normal,
    this.textSizeScale = TextSizeScale.normal,
    this.fontWeightScale = FontWeightScale.normal,
    this.notificationsEnabled = true,
    this.isLoaded = false,
  });

  @override
  List<Object?> get props => [
    isDarkMode,
    language,
    colourVisionMode,
    contrastMode,
    textSizeScale,
    fontWeightScale,
    notificationsEnabled,
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
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
