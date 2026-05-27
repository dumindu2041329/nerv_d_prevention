import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/timeline_event.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isIslandWide = true;
  SLDistrict? _selectedDistrict;

  void _updateDistrict(bool isNational, SLDistrict? district) {
    setState(() {
      _isIslandWide = isNational;
      _selectedDistrict = district;
    });
    if (district != null) {
      context.read<WeatherBloc>().add(
        LoadWeatherForDistrict(district: district),
      );
    } else {
      context.read<WeatherBloc>().add(const LoadWeather());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              NationalLocalToggle(
                isNational: _isIslandWide,
                selectedDistrict: _selectedDistrict,
                onChanged: (isNational) {
                  _updateDistrict(isNational, null);
                },
                onDistrictSelected: (district) {
                  _updateDistrict(false, district);
                },
              ),
              Expanded(child: _buildTimelineContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
          );
        }

        if (state is WeatherError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          );
        }

        if (state is WeatherLoaded) {
          final events = WeatherAlertDeriver.deriveTimelineEvents(
            state.weatherData,
            districtName: state.selectedDistrict?.displayName,
          );
          return _buildTimelineList(context, events);
        }

        return Center(
          child: Text(
            'Loading timeline...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineList(BuildContext context, List<TimelineEvent> events) {
    final grouped = _groupEventsByDate(events);

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No active alerts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Weather conditions are calm',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return _buildDateGroup(context, group, grouped);
      },
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    _DateGroup group,
    List<_DateGroup> allGroups,
  ) {
    final groupIndex = allGroups.indexOf(group);

    return Column(
      children: [
        // Date separator pill
        _buildDateSeparator(group.label),
        // Events in this group
        ...group.events.asMap().entries.map((entry) {
          final isFirst = entry.key == 0 && groupIndex == 0;
          final isLast =
              entry.key == group.events.length - 1 &&
              groupIndex == allGroups.length - 1;
          return _buildEventItem(context, entry.value, isFirst, isLast);
        }),
      ],
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    TimelineEvent event,
    bool isFirst,
    bool isLast,
  ) {
    final isHighlighted = isFirst;
    final color = event.severity.color;
    final isLifted = event.isLifted;

    return IntrinsicHeight(
      child: Container(
        color: isHighlighted ? const Color(0xFF1A1A1A) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column (left)
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  DateTimeUtils.formatTime(event.time),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Timeline line + dot
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // Top connector line
                  Container(
                    width: 1.5,
                    height: 16,
                    color: isFirst
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                  // Circle dot with severity color
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLifted
                          ? Colors.black
                          : color.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isLifted
                            ? Colors.white.withValues(alpha: 0.25)
                            : color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getEventIcon(event.type),
                        size: 16,
                        color: isLifted
                            ? Colors.white.withValues(alpha: 0.4)
                            : color.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  // Bottom connector line
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isLast
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            // Content (right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getEventTypeLabel(event.type),
                                  style: TextStyle(
                                    color: isLifted
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isLifted) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIFTED',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.title,
                              style: TextStyle(
                                color: isLifted
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTypeLabel(String type) {
    final alertType = SLAlertType.fromString(type);
    if (alertType != null) return alertType.fullLabel;

    switch (type) {
      case 'flood':
        return 'Flood Warning';
      case 'landslide':
        return 'Landslide Alert';
      case 'cyclone':
        return 'Cyclone Advisory';
      case 'lightning':
        return 'Lightning Alert';
      case 'coastal':
      case 'coastalWarning':
        return 'Coastal Warning';
      case 'tsunami':
        return 'Tsunami Bulletin';
      case 'earthquake':
        return 'Earthquake Info';
      default:
        return 'Information';
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'flood':
        return Icons.water;
      case 'landslide':
        return Icons.terrain;
      case 'cyclone':
        return Icons.cyclone;
      case 'lightning':
        return Icons.bolt;
      case 'coastal':
      case 'coastalWarning':
        return Icons.beach_access;
      case 'tsunami':
        return Icons.waves;
      case 'earthquake':
        return Icons.public;
      default:
        return Icons.info;
    }
  }

  List<_DateGroup> _groupEventsByDate(List<TimelineEvent> events) {
    final Map<String, List<TimelineEvent>> groups = {};

    for (final event in events) {
      final now = DateTime.now();
      final eventDate = DateTime(
        event.time.year,
        event.time.month,
        event.time.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      String label;
      if (eventDate == today) {
        label = 'Today';
      } else if (eventDate == yesterday) {
        label = 'Yesterday';
      } else if (eventDate == tomorrow) {
        label = 'Tomorrow';
      } else {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        label =
            '${days[event.time.weekday - 1]} ${event.time.month}/${event.time.day}';
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(event);
    }

    return groups.entries.map((e) => _DateGroup(e.key, e.value)).toList();
  }
}

class _DateGroup {
  final String label;
  final List<TimelineEvent> events;

  const _DateGroup(this.label, this.events);
}

class TimelineFilterData {
  final String id;
  final String label;

  const TimelineFilterData({required this.id, required this.label});
}
