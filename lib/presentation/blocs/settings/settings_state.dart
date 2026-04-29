part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final ColourVisionMode colourVisionMode;
  final ContrastMode contrastMode;
  final TextSizeScale textSizeScale;
  final FontWeightScale fontWeightScale;
  final bool isLoaded;

  const SettingsState({
    this.isDarkMode = true,
    this.colourVisionMode = ColourVisionMode.normal,
    this.contrastMode = ContrastMode.normal,
    this.textSizeScale = TextSizeScale.normal,
    this.fontWeightScale = FontWeightScale.normal,
    this.isLoaded = false,
  });

  @override
  List<Object?> get props => [
        isDarkMode,
        colourVisionMode,
        contrastMode,
        textSizeScale,
        fontWeightScale,
        isLoaded,
      ];

  SettingsState copyWith({
    bool? isDarkMode,
    ColourVisionMode? colourVisionMode,
    ContrastMode? contrastMode,
    TextSizeScale? textSizeScale,
    FontWeightScale? fontWeightScale,
    bool? isLoaded,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      colourVisionMode: colourVisionMode ?? this.colourVisionMode,
      contrastMode: contrastMode ?? this.contrastMode,
      textSizeScale: textSizeScale ?? this.textSizeScale,
      fontWeightScale: fontWeightScale ?? this.fontWeightScale,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
