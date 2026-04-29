import 'package:equatable/equatable.dart';
import '../../core/constants/app_colors.dart';

class Alert extends Equatable {
  final String id;
  final String type;
  final String headline;
  final String description;
  final SeverityLevel severity;
  final DateTime issuedTime;
  final DateTime? expiryTime;
  final String location;
  final Map<String, dynamic>? metadata;

  const Alert({
    required this.id,
    required this.type,
    required this.headline,
    required this.description,
    required this.severity,
    required this.issuedTime,
    this.expiryTime,
    required this.location,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        headline,
        description,
        severity,
        issuedTime,
        expiryTime,
        location,
        metadata,
      ];
}
