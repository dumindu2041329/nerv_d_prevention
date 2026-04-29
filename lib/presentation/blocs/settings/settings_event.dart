part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class ToggleDarkMode extends SettingsEvent {
  const ToggleDarkMode();
}

class SetColourVisionMode extends SettingsEvent {
  final ColourVisionMode mode;

  const SetColourVisionMode({required this.mode});

  @override
  List<Object?> get props => [mode];
}

class SetContrastMode extends SettingsEvent {
  final ContrastMode mode;

  const SetContrastMode({required this.mode});

  @override
  List<Object?> get props => [mode];
}

class SetTextSizeScale extends SettingsEvent {
  final TextSizeScale scale;

  const SetTextSizeScale({required this.scale});

  @override
  List<Object?> get props => [scale];
}

class SetFontWeightScale extends SettingsEvent {
  final FontWeightScale scale;

  const SetFontWeightScale({required this.scale});

  @override
  List<Object?> get props => [scale];
}
