class WeatherCodeMapping {
  static const Map<int, String> accuWeatherCodeToDescription = {
    1: 'Sunny',
    2: 'Mostly Sunny',
    3: 'Partly Sunny',
    4: 'Intermittent Clouds',
    5: 'Hazy Sunshine',
    6: 'Mostly Cloudy',
    7: 'Cloudy',
    8: 'Overcast',
    9: 'Showers',
    10: 'Showers',
    11: 'Light Rain',
    12: 'Rain',
    13: 'Rain',
    14: 'Thunderstorms',
    15: 'Mostly Cloudy with Showers',
    16: 'Mostly Cloudy with T-Storms',
    17: 'Partly Sunny with Showers',
    18: 'Partly Sunny with T-Storms',
    19: 'Flurries',
    20: 'Mostly Cloudy with Flurries',
    21: 'Partly Sunny with Flurries',
    22: 'Snow',
    23: 'Snow',
    24: 'Sleet',
    25: 'Freezing Rain',
    26: 'Rain and Sleet',
    27: 'Mostly Cloudy with Sleet',
    28: 'Mostly Cloudy with Rain',
    29: 'Mostly Cloudy with Rain',
    30: 'Mostly Cloudy',
    31: 'Partly Cloudy',
    32: 'Windy',
    33: 'Clear',
    34: 'Mostly Clear',
    35: 'Partly Cloudy',
    36: 'Intermittent Clouds',
    37: 'Hazy Moonlight',
    38: 'Mostly Cloudy',
    39: 'Partly Cloudy with Showers',
    40: 'Mostly Cloudy with Showers',
    41: 'Foggy',
    42: 'Foggy',
    43: 'Mostly Cloudy and Cold',
    44: 'Mostly Cloudy',
    45: 'Rain Late',
    46: 'Rain Late',
    47: 'Mostly Cloudy with Showers',
  };

  static String getDescription(int code) {
    return accuWeatherCodeToDescription[code] ?? 'Unknown';
  }

  static String getIcon(int code) {
    return _getAccuWeatherIcon(code);
  }

  static String _getAccuWeatherIcon(int code) {
    switch (code) {
      case 1:
      case 2:
      case 33:
      case 34:
        return '☀️';
      case 3:
      case 4:
      case 31:
      case 35:
      case 36:
        return '⛅';
      case 5:
      case 37:
        return '🌤';
      case 6:
      case 7:
      case 8:
      case 30:
      case 38:
      case 43:
      case 44:
        return '☁️';
      case 9:
      case 10:
      case 39:
      case 40:
      case 45:
      case 46:
      case 47:
        return '🌧️';
      case 11:
      case 12:
      case 13:
      case 28:
      case 29:
        return '🌧️';
      case 14:
      case 16:
      case 18:
        return '⛈️';
      case 15:
      case 17:
        return '🌦️';
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
      case 41:
      case 42:
        return '🌨️';
      case 24:
      case 25:
      case 26:
      case 27:
        return '🌨️';
      case 32:
        return '💨';
      default:
        return '❓';
    }
  }
}