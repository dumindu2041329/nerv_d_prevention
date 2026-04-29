class StringUtils {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String formatTemperature(double temp, {bool showUnit = true}) {
    final rounded = temp.round();
    return showUnit ? '$rounded°C' : '$rounded°';
  }

  static String formatWindSpeed(double speed) {
    return '${speed.round()} km/h';
  }

  static String formatPercentage(double value) {
    return '${value.round()}%';
  }

  static String formatPrecipitation(double mm) {
    if (mm < 1) return '< 1mm';
    return '${mm.round()}mm';
  }

  static String getWindDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}
