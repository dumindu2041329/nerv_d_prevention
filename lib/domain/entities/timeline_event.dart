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

  // Detail-screen fields. Populated by [WeatherAlertDeriver] from the
  // underlying WeatherAPI.com data. All optional so older cached events
  // (or events from other sources) remain valid.
  final int? maxIntensity;
  final double? magnitude;
  final String? magnitudeLabel;
  final double? depthKm;
  final String? depthLabel;
  final bool tsunamiFlag;
  final double? latitude;
  final double? longitude;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.location,
    required this.severity,
    required this.time,
    this.isLifted = false,
    this.maxIntensity,
    this.magnitude,
    this.magnitudeLabel,
    this.depthKm,
    this.depthLabel,
    this.tsunamiFlag = false,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        location,
        severity,
        time,
        isLifted,
        maxIntensity,
        magnitude,
        magnitudeLabel,
        depthKm,
        depthLabel,
        tsunamiFlag,
        latitude,
        longitude,
      ];
}
