import 'package:equatable/equatable.dart';

class Location extends Equatable {
  final String id;
  final String name;
  final String? country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final bool isGps;

  const Location({
    required this.id,
    required this.name,
    this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
    this.isGps = false,
  });

  String get displayName {
    final parts = <String>[name];
    if (admin1 != null) parts.add(admin1!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [id, name, country, admin1, latitude, longitude, isGps];
}
