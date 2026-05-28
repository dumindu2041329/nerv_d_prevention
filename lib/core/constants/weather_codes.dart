class WeatherCodeMapping {
  /// WeatherAPI.com condition codes → description
  static const Map<int, String> _codeToDescription = {
    1000: 'Sunny',
    1003: 'Partly Cloudy',
    1006: 'Cloudy',
    1009: 'Overcast',
    1030: 'Mist',
    1063: 'Patchy Rain',
    1066: 'Patchy Snow',
    1069: 'Patchy Sleet',
    1072: 'Freezing Drizzle',
    1087: 'Thundery Outbreaks',
    1114: 'Blowing Snow',
    1117: 'Blizzard',
    1135: 'Fog',
    1147: 'Freezing Fog',
    1150: 'Light Drizzle',
    1153: 'Light Drizzle',
    1168: 'Freezing Drizzle',
    1171: 'Heavy Freezing Drizzle',
    1180: 'Light Rain',
    1183: 'Light Rain',
    1186: 'Moderate Rain',
    1189: 'Moderate Rain',
    1192: 'Heavy Rain',
    1195: 'Heavy Rain',
    1198: 'Light Freezing Rain',
    1201: 'Moderate Freezing Rain',
    1204: 'Light Sleet',
    1207: 'Moderate Sleet',
    1210: 'Light Snow',
    1213: 'Light Snow',
    1216: 'Moderate Snow',
    1219: 'Moderate Snow',
    1222: 'Heavy Snow',
    1225: 'Heavy Snow',
    1237: 'Ice Pellets',
    1240: 'Light Rain Shower',
    1243: 'Moderate Rain Shower',
    1246: 'Heavy Rain Shower',
    1249: 'Light Sleet Shower',
    1252: 'Moderate Sleet Shower',
    1255: 'Light Snow Shower',
    1258: 'Heavy Snow Shower',
    1261: 'Light Ice Pellets',
    1264: 'Moderate Ice Pellets',
    1273: 'Thunderstorm with Rain',
    1276: 'Thunderstorm with Heavy Rain',
    1279: 'Thunderstorm with Snow',
    1282: 'Thunderstorm with Heavy Snow',
  };

  static String getDescription(int code) =>
      _codeToDescription[code] ?? 'Unknown';

  static String getIcon(int code) {
    if (code == 1000) return '☀️';
    if (code == 1003) return '⛅';
    if (code == 1006 || code == 1009) return '☁️';
    if (code == 1030 || code == 1135 || code == 1147) return '🌫️';
    if (code >= 1063 && code <= 1072) return '🌦️';
    if (code == 1087 || code == 1273 || code == 1276 || code == 1279 || code == 1282) return '⛈️';
    if (code == 1114 || code == 1117) return '🌨️';
    if (code >= 1150 && code <= 1201) return '🌧️';
    if (code >= 1204 && code <= 1237) return '🌨️';
    if (code >= 1240 && code <= 1246) return '🌧️';
    if (code >= 1249 && code <= 1264) return '🌨️';
    return '❓';
  }
}
