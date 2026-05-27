import 'package:latlong2/latlong.dart';

/// Sri Lanka-specific constants for the NERV Disaster Prevention App.
/// Defines districts, alert types, major cities, and map bounds.

// ──────────────────────────────────────────────────────────────────────
// Map Bounds & Coordinates
// ──────────────────────────────────────────────────────────────────────

class SLMapConstants {
  SLMapConstants._();

  /// Geographic center of Sri Lanka (near Dambulla)
  static const LatLng center = LatLng(7.8731, 80.7718);

  /// Initial zoom level showing the entire island
  static const double initialZoom = 7.2;

  /// Minimum zoom (shows all of Sri Lanka with surrounding ocean)
  static const double minZoom = 6.0;

  /// Maximum zoom for street-level detail
  static const double maxZoom = 18.0;

  /// South-west bound of Sri Lanka
  static const LatLng southWest = LatLng(5.9167, 79.5333);

  /// North-east bound of Sri Lanka
  static const LatLng northEast = LatLng(9.8167, 81.8167);
}

// ──────────────────────────────────────────────────────────────────────
// 25 Districts of Sri Lanka
// ──────────────────────────────────────────────────────────────────────

enum SLDistrict {
  colombo('Colombo', 'Western', LatLng(6.9271, 79.8612)),
  gampaha('Gampaha', 'Western', LatLng(7.0867, 80.0128)),
  kalutara('Kalutara', 'Western', LatLng(6.5854, 79.9607)),
  kandy('Kandy', 'Central', LatLng(7.2906, 80.6337)),
  matale('Matale', 'Central', LatLng(7.4675, 80.6234)),
  nuwaraEliya('Nuwara Eliya', 'Central', LatLng(6.9497, 80.7891)),
  galle('Galle', 'Southern', LatLng(6.0535, 80.2210)),
  matara('Matara', 'Southern', LatLng(5.9485, 80.5353)),
  hambantota('Hambantota', 'Southern', LatLng(6.1241, 81.1185)),
  jaffna('Jaffna', 'Northern', LatLng(9.6683, 80.0074)),
  kilinochchi('Kilinochchi', 'Northern', LatLng(9.3929, 80.4041)),
  mannar('Mannar', 'Northern', LatLng(8.9802, 79.9043)),
  vavuniya('Vavuniya', 'Northern', LatLng(8.7577, 80.4993)),
  mullaitivu('Mullaitivu', 'Northern', LatLng(9.2670, 80.8140)),
  batticaloa('Batticaloa', 'Eastern', LatLng(7.7167, 81.7000)),
  ampara('Ampara', 'Eastern', LatLng(7.2833, 81.6667)),
  trincomalee('Trincomalee', 'Eastern', LatLng(8.5874, 81.2152)),
  kurunegala('Kurunegala', 'North Western', LatLng(7.4875, 80.3647)),
  puttalam('Puttalam', 'North Western', LatLng(8.0362, 79.8287)),
  anuradhapura('Anuradhapura', 'North Central', LatLng(8.3114, 80.4037)),
  polonnaruwa('Polonnaruwa', 'North Central', LatLng(7.9403, 81.0188)),
  badulla('Badulla', 'Uva', LatLng(6.9897, 81.0557)),
  monaragala('Monaragala', 'Uva', LatLng(6.8728, 81.3507)),
  ratnapura('Ratnapura', 'Sabaragamuwa', LatLng(6.6828, 80.3994)),
  kegalle('Kegalle', 'Sabaragamuwa', LatLng(7.2539, 80.3535));

  const SLDistrict(this.displayName, this.province, this.center);

  /// Human-readable district name (e.g. "Colombo")
  final String displayName;

  /// Province the district belongs to (e.g. "Western")
  final String province;

  /// Geographic center coordinates of the district
  final LatLng center;

  /// All districts sorted alphabetically by displayName
  static List<SLDistrict> get alphabetical =>
      values.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  /// Districts grouped by province
  static Map<String, List<SLDistrict>> get byProvince {
    final map = <String, List<SLDistrict>>{};
    for (final d in values) {
      map.putIfAbsent(d.province, () => []);
      map[d.province]!.add(d);
    }
    return map;
  }
}

// ──────────────────────────────────────────────────────────────────────
// DMC Sri Lanka Alert Types
// ──────────────────────────────────────────────────────────────────────

/// Disaster alert types matching Sri Lanka Disaster Management Centre categories.
enum SLAlertType {
  flood('Flood', 'Flood Warning', '#FF6D00', 'water'),
  landslide('Landslide', 'Landslide Alert', '#FF6D00', 'terrain'),
  cyclone('Cyclone', 'Cyclone Advisory', '#FF1744', 'cyclone'),
  lightning('Lightning', 'Lightning Alert', '#FFC400', 'bolt'),
  coastalWarning(
    'Coastal Warning',
    'Coastal Warning',
    '#00E5FF',
    'beach_access',
  ),
  tsunami('Tsunami', 'Tsunami Bulletin', '#FF1744', 'waves');

  const SLAlertType(
    this.label,
    this.fullLabel,
    this.hexColor,
    this.materialIconName,
  );

  /// Short label (e.g. "Flood")
  final String label;

  /// Full label for display (e.g. "Flood Warning")
  final String fullLabel;

  /// Severity hex color
  final String hexColor;

  /// Name of the Material Icons icon for this alert type
  final String materialIconName;

  /// Parse from a timeline event / alert type string
  static SLAlertType? fromString(String type) {
    for (final t in values) {
      if (t.name == type || t.label.toLowerCase() == type.toLowerCase()) {
        return t;
      }
    }
    return null;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Major Sri Lankan Cities
// ──────────────────────────────────────────────────────────────────────

class SLCity {
  final String name;
  final LatLng coordinates;
  final SLDistrict district;

  const SLCity(this.name, this.coordinates, this.district);
}

class SLCityConstants {
  SLCityConstants._();

  /// 12 major cities used on the Weather screen.
  static const List<SLCity> majorCities = [
    SLCity('Colombo', LatLng(6.9271, 79.8612), SLDistrict.colombo),
    SLCity('Kandy', LatLng(7.2906, 80.6337), SLDistrict.kandy),
    SLCity('Galle', LatLng(6.0535, 80.2210), SLDistrict.galle),
    SLCity('Jaffna', LatLng(9.6683, 80.0074), SLDistrict.jaffna),
    SLCity('Batticaloa', LatLng(7.7167, 81.7000), SLDistrict.batticaloa),
    SLCity('Trincomalee', LatLng(8.5874, 81.2152), SLDistrict.trincomalee),
    SLCity('Anuradhapura', LatLng(8.3114, 80.4037), SLDistrict.anuradhapura),
    SLCity('Ratnapura', LatLng(6.6828, 80.3994), SLDistrict.ratnapura),
    SLCity('Badulla', LatLng(6.9897, 81.0557), SLDistrict.badulla),
    SLCity('Kurunegala', LatLng(7.4875, 80.3647), SLDistrict.kurunegala),
    SLCity('Matara', LatLng(5.9485, 80.5353), SLDistrict.matara),
    SLCity('Hambantota', LatLng(6.1241, 81.1185), SLDistrict.hambantota),
  ];
}

// ──────────────────────────────────────────────────────────────────────
// Monsoon Seasons
// ──────────────────────────────────────────────────────────────────────

enum SLMonsoon {
  southWest(
    'SW Monsoon',
    'May–September',
    'Wet in south-west, dry in north-east',
  ),
  northEast(
    'NE Monsoon',
    'December–February',
    'Wet in north-east, dry in south-west',
  ),
  interMonsoon1(
    '1st Inter-Monsoon',
    'March–April',
    'Thunderstorms island-wide',
  ),
  interMonsoon2(
    '2nd Inter-Monsoon',
    'October–November',
    'Thunderstorms island-wide',
  );

  const SLMonsoon(this.name, this.period, this.description);

  final String name;
  final String period;
  final String description;

  /// Returns the current monsoon season based on the month.
  static SLMonsoon current(DateTime date) {
    final m = date.month;
    if (m >= 5 && m <= 9) return southWest;
    if (m == 12 || m <= 2) return northEast;
    if (m >= 3 && m <= 4) return interMonsoon1;
    return interMonsoon2; // October–November
  }
}
