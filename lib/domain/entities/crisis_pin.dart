import 'package:equatable/equatable.dart';

enum CrisisPinType {
  shelter,
  water,
  toilet,
  road,
  waste,
  reliefSupply;

  String get label {
    switch (this) {
      case CrisisPinType.shelter:
        return 'Shelter';
      case CrisisPinType.water:
        return 'Water';
      case CrisisPinType.toilet:
        return 'Toilet';
      case CrisisPinType.road:
        return 'Road';
      case CrisisPinType.waste:
        return 'Waste';
      case CrisisPinType.reliefSupply:
        return 'Relief Supply';
    }
  }

  String get icon {
    switch (this) {
      case CrisisPinType.shelter:
        return '🏠';
      case CrisisPinType.water:
        return '💧';
      case CrisisPinType.toilet:
        return '🚻';
      case CrisisPinType.road:
        return '🛣️';
      case CrisisPinType.waste:
        return '🗑️';
      case CrisisPinType.reliefSupply:
        return '📦';
    }
  }
}

class CrisisPin extends Equatable {
  final String id;
  final CrisisPinType type;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final int? capacity;
  final bool isOpen;
  final DateTime postedAt;
  final DateTime? updatedAt;
  final String? postedBy;
  final bool isVerified;
  final int watchCount;

  const CrisisPin({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.capacity,
    this.isOpen = true,
    required this.postedAt,
    this.updatedAt,
    this.postedBy,
    this.isVerified = false,
    this.watchCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        description,
        latitude,
        longitude,
        address,
        capacity,
        isOpen,
        postedAt,
        updatedAt,
        postedBy,
        isVerified,
        watchCount,
      ];
}
