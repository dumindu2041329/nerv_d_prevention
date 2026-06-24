import 'package:equatable/equatable.dart';

class LandslideZone extends Equatable {
  final String id;
  final String name;
  final String severity;
  final String source;
  final double? latitude;
  final double? longitude;
  final String? district;
  final List<List<double>>? polygonRings;
  final bool isActive;

  const LandslideZone({
    required this.id,
    required this.name,
    required this.severity,
    required this.source,
    this.latitude,
    this.longitude,
    this.district,
    this.polygonRings,
    this.isActive = true,
  });

  bool get isPolygon => polygonRings != null && polygonRings!.length >= 3;
  bool get isPoint => latitude != null && longitude != null && !isPolygon;

  @override
  List<Object?> get props => [
        id,
        name,
        severity,
        source,
        latitude,
        longitude,
        district,
        polygonRings,
        isActive,
      ];
}
