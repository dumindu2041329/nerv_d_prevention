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

  static String getDescription(int code, {bool isDay = true}) {
    if (code == 1000) return isDay ? 'Sunny' : 'Clear';
    return _codeToDescription[code] ?? 'Unknown';
  }

  static String getIcon(int code, {bool isDay = true}) {
    switch (code) {
      case 1000: return isDay ? '☀️' : '🌙';
      case 1003: return isDay ? '⛅' : '🌙';
      case 1006:
      case 1009: return '☁️';
      case 1030:
      case 1135:
      case 1147: return '🌫️';
      case 1063:
      case 1180:
      case 1183:
      case 1186:
      case 1189:
      case 1192:
      case 1195:
      case 1240:
      case 1243:
      case 1246: return '🌧️';
      case 1066:
      case 1114:
      case 1117:
      case 1210:
      case 1213:
      case 1216:
      case 1219:
      case 1222:
      case 1225:
      case 1255:
      case 1258: return '🌨️';
      case 1069:
      case 1072:
      case 1150:
      case 1153:
      case 1168:
      case 1171:
      case 1198:
      case 1201:
      case 1204:
      case 1207:
      case 1249:
      case 1252: return '🌧️';
      case 1237:
      case 1261:
      case 1264: return '🧊';
      case 1087:
      case 1273:
      case 1276:
      case 1279:
      case 1282: return '⛈️';
      default: return '🌡️';
    }
  }
}
