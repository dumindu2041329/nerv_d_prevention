import 'package:equatable/equatable.dart';
import '../../core/constants/app_sl_constants.dart';

class Location extends Equatable {
  final String id;
  final String name;
  final String? country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final bool isGps;
  final SLDistrict? district;

  const Location({
    required this.id,
    required this.name,
    this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
    this.isGps = false,
    this.district,
  });

  String get displayName {
    final parts = <String>[name];
    if (admin1 != null) parts.add(admin1!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  /// Whether this location is associated with a recognized Sri Lankan district.
  bool get isSLDistrict => district != null;

  @override
  List<Object?> get props => [
    id,
    name,
    country,
    admin1,
    latitude,
    longitude,
    isGps,
    district,
  ];
}
