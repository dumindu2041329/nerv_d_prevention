import 'package:flutter/widgets.dart';
import '../constants/app_colors.dart';

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationScope>();
    if (scope == null) {
      throw FlutterError(
        'AppLocalizations.of() called with no AppLocalizationScope in context.',
      );
    }
    return scope.localizations;
  }

  String t(String key) {
    final table =
        _translations[language] ?? _translations[AppLanguage.english]!;
    return table[key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      'menu.title': 'Menu',
      'menu.language': 'Language',
      'menu.about': 'About this app',
      'menu.savedRegions': 'Saved Regions',
      'menu.add': 'Add',
      'menu.none': 'None',
      'menu.canAddUpTo': 'You can add up to 3 regions',
      'menu.version': 'Version',
      'menu.aboutVersion': 'About NERV',
      'menu.language.english': 'English',
      'menu.language.sinhala': 'සිංහල',
      'menu.language.tamil': 'தமிழ்',
      'nav.home': 'Home',
      'nav.timeline': 'Timeline',
      'nav.map': 'Map',
      'nav.weather': 'Weather',
      'nav.menu': 'Menu',

      'settings.title': 'Settings',
      'settings.accessibility': 'Accessibility',
      'settings.displayText': 'Display & Text',
      'settings.darkMode': 'Dark Mode',
      'settings.textSize': 'Text Size',
      'settings.fontWeight': 'Font Weight',
      'settings.colourVision': 'Colour Vision',
      'settings.contrast': 'Contrast',
      'settings.notifications': 'Notifications',
      'settings.alertSettings': 'Alert Settings',
      'settings.criticalAlerts': 'Critical Alerts',
      'settings.floodAlerts': 'Flood Alerts',
      'settings.landslideAlerts': 'Landslide Alerts',
      'settings.cycloneAdvisories': 'Cyclone Advisories',
      'settings.lightningAlerts': 'Lightning Alerts',
      'settings.coastalWarnings': 'Coastal Warnings',
      'settings.tsunamiBulletins': 'Tsunami Bulletins',
      'settings.about': 'About',
      'settings.appInformation': 'App Information',
      'settings.aboutNerv': 'About NERV',
      'settings.privacyPolicy': 'Privacy Policy',
      'settings.termsOfService': 'Terms of Service',
      'settings.close': 'Close',
      'settings.version': 'Version 1.0.0',
      'settings.weatherDataProvidedBy':
          'Weather data provided by WeatherAPI.com.',
      'settings.alertsDmc': 'Alerts: DMC Sri Lanka',
      'settings.weatherOpenMeteo': 'Weather data: Open-Meteo',

      'home.loadingWeather': 'Loading weather...',
      'home.weatherUnavailable': 'Weather data unavailable',
      'home.islandWide': 'Island-wide',
      'home.local': 'Local',
      'home.sosStalePrefix': 'SOS alerts may be out of date — last updated ',
      'home.never': 'never',
      'home.justNow': 'just now',
      'home.minAgo': 'min ago',
      'home.hrAgo': 'hr ago',
      'home.dAgo': 'd ago',
      'home.feelsLike': 'Feels like',
      'home.humidity': 'Humidity',
      'home.wind': 'Wind',

      'timeline.loading': 'Loading timeline...',
      'timeline.noActiveAlerts': 'No active alerts',
      'timeline.conditionsCalm': 'Weather conditions are calm',
      'timeline.today': 'Today',
      'timeline.yesterday': 'Yesterday',
      'timeline.tomorrow': 'Tomorrow',
      'timeline.info': 'Information',
      'timeline.event.flood': 'Flood Warning',
      'timeline.event.landslide': 'Landslide Alert',
      'timeline.event.cyclone': 'Cyclone Advisory',
      'timeline.event.lightning': 'Lightning Alert',
      'timeline.event.coastal': 'Coastal Warning',
      'timeline.event.tsunami': 'Tsunami Bulletin',
      'timeline.event.earthquake': 'Earthquake Info',

      'timeline.weekday.mon': 'Mon',
      'timeline.weekday.tue': 'Tue',
      'timeline.weekday.wed': 'Wed',
      'timeline.weekday.thu': 'Thu',
      'timeline.weekday.fri': 'Fri',
      'timeline.weekday.sat': 'Sat',
      'timeline.weekday.sun': 'Sun',
    },
    AppLanguage.sinhala: {
      'menu.title': 'මෙනුව',
      'menu.language': 'භාෂාව',
      'menu.about': 'මෙම යෙදුම පිළිබඳ',
      'menu.savedRegions': 'සුරකින ලද ප්‍රදේශ',
      'menu.add': 'එකතු කරන්න',
      'menu.none': 'නැත',
      'menu.canAddUpTo': 'ඔබට ප්‍රදේශ 3ක් දක්වා එකතු කළ හැක',
      'menu.version': 'වෙළුම',
      'menu.aboutVersion': 'NERV පිළිබඳ',
      'menu.language.english': 'ඉංග්‍රීසි',
      'menu.language.sinhala': 'සිංහල',
      'menu.language.tamil': 'தமிழ்',

      'nav.home': 'මුල් පිටුව',
      'nav.timeline': 'කාලරාමුව',
      'nav.map': 'සිතියම',
      'nav.weather': 'කාලගුණය',
      'nav.menu': 'මෙනුව',

      'settings.title': 'සැකසුම්',
      'settings.accessibility': 'ප්‍රවේශය (Accessibility)',
      'settings.displayText': 'දර්ශනය සහ පෙළ',
      'settings.darkMode': 'අඳුරු මාදිලිය',
      'settings.textSize': 'පෙළ ප්‍රමාණය',
      'settings.fontWeight': 'අකුරු බර',
      'settings.colourVision': 'වර්ණ දැක්ම',
      'settings.contrast': 'ප්‍රතිවිරෝධතාව',
      'settings.notifications': 'දැනුම්දීම්',
      'settings.alertSettings': 'අනතුරු සැකසුම්',
      'settings.criticalAlerts': 'ප්‍රධාන අනතුරු',
      'settings.floodAlerts': 'ගංවතුර අනතුරු',
      'settings.landslideAlerts': 'කඳු කඩා වැටීම් අනතුරු',
      'settings.cycloneAdvisories': 'සුළි කුණාටු උපදෙස්',
      'settings.lightningAlerts': 'අකුණු අනතුරු',
      'settings.coastalWarnings': 'වරාය/මුහුදු වෙරළ අනතුරු',
      'settings.tsunamiBulletins': 'සුනාමී නිවේදන',
      'settings.about': 'පිළිබඳ',
      'settings.appInformation': 'යෙදුම් තොරතුරු',
      'settings.aboutNerv': 'NERV පිළිබඳ',
      'settings.privacyPolicy': 'පුද්ගලිකත්ව ප්‍රතිපත්තිය',
      'settings.termsOfService': 'සේවා නියමයන්',
      'settings.close': 'වසා දමන්න',
      'settings.version': 'වෙළුම 1.0.0',
      'settings.weatherDataProvidedBy':
          'WeatherAPI.com මගින් ලබා දෙන කාලගුණ දත්ත.',
      'settings.alertsDmc': 'අනතුරු: DMC ශ්‍රී ලංකාව',
      'settings.weatherOpenMeteo': 'කාලගුණ දත්ත: Open-Meteo',

      'home.loadingWeather': 'කාලගුණය ලෝඩ් කරමින්...',
      'home.weatherUnavailable': 'කාලගුණ දත්ත ලබා ගත නොහැක',
      'home.islandWide': 'දූපත් පුරා',
      'home.local': 'දේශීය',
      'home.sosStalePrefix':
          'SOS අනතුරු ප්‍රමාද විය හැක — අවසන් වර යාවත්කාලීන කළේ ',
      'home.never': 'කවදාවත් නැත',
      'home.justNow': 'මොහොතකට පෙර',
      'home.minAgo': 'මිනිත්තු පෙර',
      'home.hrAgo': 'පැය පෙර',
      'home.dAgo': 'දින පෙර',
      'home.feelsLike': 'දැනෙන උෂ්ණත්වය',
      'home.humidity': 'තෙතමනය',
      'home.wind': 'සුළං වේගය',

      'timeline.loading': 'කාලරාමුව ලෝඩ් කරමින්...',
      'timeline.noActiveAlerts': 'සක්‍රීය අනතුරු නැත',
      'timeline.conditionsCalm': 'කාලගුණ තත්ත්වය සන්සුන්',
      'timeline.today': 'අද',
      'timeline.yesterday': 'ඊයේ',
      'timeline.tomorrow': 'හෙට',
      'timeline.info': 'තොරතුරු',
      'timeline.event.flood': 'ගංවතුර අනතුරු',
      'timeline.event.landslide': 'කඳු කඩා වැටීම් අනතුරු',
      'timeline.event.cyclone': 'සුළි කුණාටු උපදෙස්',
      'timeline.event.lightning': 'අකුණු අනතුරු',
      'timeline.event.coastal': 'වරාය/මුහුදු වෙරළ අනතුරු',
      'timeline.event.tsunami': 'සුනාමී නිවේදන',
      'timeline.event.earthquake': 'භූමිකම්පාව පිළිබඳ තොරතුරු',

      'timeline.weekday.mon': 'සඳුදා',
      'timeline.weekday.tue': 'අඟහරුවාදා',
      'timeline.weekday.wed': 'බදාදා',
      'timeline.weekday.thu': 'බ්‍රහස්පතින්දා',
      'timeline.weekday.fri': 'සිකුරාදා',
      'timeline.weekday.sat': 'සෙනසුරාදා',
      'timeline.weekday.sun': 'ඉරිදා',
    },
    AppLanguage.tamil: {
      'menu.title': 'மெனு',
      'menu.language': 'மொழி',
      'menu.about': 'இந்த செயலி பற்றி',
      'menu.savedRegions': 'சேமித்த பகுதிகள்',
      'menu.add': 'சேர்',
      'menu.none': 'இல்லை',
      'menu.canAddUpTo': 'அதிகபட்சம் 3 பகுதிகள் வரை சேர்க்கலாம்',
      'menu.version': 'பதிப்பு',
      'menu.aboutVersion': 'NERV பற்றி',
      'menu.language.english': 'English',
      'menu.language.sinhala': 'සිංහල',
      'menu.language.tamil': 'தமிழ்',

      'nav.home': 'முகப்பு',
      'nav.timeline': 'காலவரிசை',
      'nav.map': 'வரைபடம்',
      'nav.weather': 'வானிலை',
      'nav.menu': 'மெனு',

      'settings.title': 'அமைப்புகள்',
      'settings.accessibility': 'அணுகல் (Accessibility)',
      'settings.displayText': 'காட்சி & எழுத்து',
      'settings.darkMode': 'இருண்ட முறை',
      'settings.textSize': 'எழுத்து அளவு',
      'settings.fontWeight': 'எழுத்துரு தடிப்பு',
      'settings.colourVision': 'நிற பார்வை',
      'settings.contrast': 'மாறுபாடு',
      'settings.notifications': 'அறிவிப்புகள்',
      'settings.alertSettings': 'எச்சரிக்கை அமைப்புகள்',
      'settings.criticalAlerts': 'முக்கிய எச்சரிக்கைகள்',
      'settings.floodAlerts': 'வெள்ள எச்சரிக்கைகள்',
      'settings.landslideAlerts': 'மண் சரிவு எச்சரிக்கைகள்',
      'settings.cycloneAdvisories': 'சூறாவளி அறிவுறுத்தல்கள்',
      'settings.lightningAlerts': 'மின்னல் எச்சரிக்கைகள்',
      'settings.coastalWarnings': 'கரையோர எச்சரிக்கைகள்',
      'settings.tsunamiBulletins': 'சுனாமி அறிவிப்புகள்',
      'settings.about': 'பற்றி',
      'settings.appInformation': 'செயலி தகவல்',
      'settings.aboutNerv': 'NERV பற்றி',
      'settings.privacyPolicy': 'தனியுரிமைக் கொள்கை',
      'settings.termsOfService': 'சேவை விதிமுறைகள்',
      'settings.close': 'மூடு',
      'settings.version': 'பதிப்பு 1.0.0',
      'settings.weatherDataProvidedBy': 'WeatherAPI.com வழங்கும் வானிலை தரவு.',
      'settings.alertsDmc': 'எச்சரிக்கைகள்: DMC இலங்கை',
      'settings.weatherOpenMeteo': 'வானிலை தரவு: Open-Meteo',

      'home.loadingWeather': 'வானிலை ஏற்றப்படுகிறது...',
      'home.weatherUnavailable': 'வானிலை தரவு கிடைக்கவில்லை',
      'home.islandWide': 'தீவு முழுவதும்',
      'home.local': 'உள்ளூர்',
      'home.sosStalePrefix':
          'SOS எச்சரிக்கைகள் காலாவதியாக இருக்கலாம் — கடைசியாக புதுப்பித்தது ',
      'home.never': 'எப்போதும் இல்லை',
      'home.justNow': 'சற்றுமுன்',
      'home.minAgo': 'நிமிடங்களுக்கு முன்',
      'home.hrAgo': 'மணிநேரங்களுக்கு முன்',
      'home.dAgo': 'நாட்களுக்கு முன்',
      'home.feelsLike': 'உணரப்படும் வெப்பநிலை',
      'home.humidity': 'ஈரப்பதம்',
      'home.wind': 'காற்று வேகம்',

      'timeline.loading': 'நேரக்கோடு ஏற்றுகிறது...',
      'timeline.noActiveAlerts': 'செயலில் எச்சரிக்கைகள் இல்லை',
      'timeline.conditionsCalm': 'வானிலை நிலைமை அமைதியாக உள்ளது',
      'timeline.today': 'இன்று',
      'timeline.yesterday': 'நேற்று',
      'timeline.tomorrow': 'நாளை',
      'timeline.info': 'தகவல்',
      'timeline.event.flood': 'வெள்ள எச்சரிக்கை',
      'timeline.event.landslide': 'மண் சரிவு எச்சரிக்கை',
      'timeline.event.cyclone': 'சூறாவளி அறிவுரை',
      'timeline.event.lightning': 'மின்னல் எச்சரிக்கை',
      'timeline.event.coastal': 'கரையோர எச்சரிக்கை',
      'timeline.event.tsunami': 'சுனாமி அறிவிப்பு',
      'timeline.event.earthquake': 'பூமி அதிர்வு தகவல்',

      'timeline.weekday.mon': 'திங்கள்',
      'timeline.weekday.tue': 'செவ்வாய்',
      'timeline.weekday.wed': 'புதன்',
      'timeline.weekday.thu': 'வியாழன்',
      'timeline.weekday.fri': 'வெள்ளி',
      'timeline.weekday.sat': 'சனி',
      'timeline.weekday.sun': 'ஞாயிறு',
    },
  };
}

/// Internal: used by AppLocalizations.of()
class AppLocalizationScope extends InheritedWidget {
  final AppLocalizations localizations;

  const AppLocalizationScope({
    required super.child,
    required this.localizations,
    super.key,
  });

  @override
  bool updateShouldNotify(covariant AppLocalizationScope oldWidget) {
    return oldWidget.localizations.language != localizations.language;
  }
}
