import 'package:equatable/equatable.dart';
import '../../core/constants/app_colors.dart';

class TimelineEvent extends Equatable {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? location;
  final SeverityLevel severity;
  final DateTime time;
  final bool isLifted;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.location,
    required this.severity,
    required this.time,
    this.isLifted = false,
  });

  @override
  List<Object?> get props => [id, type, title, description, location, severity, time, isLifted];
}
