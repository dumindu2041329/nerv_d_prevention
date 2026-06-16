import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/timeline_event.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../blocs/alerts/alert_bloc.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';
import '../../widgets/sos_alert_banner.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isIslandWide = true;
  late final WeatherBloc _weatherBloc = getIt<WeatherBloc>()
    ..add(
      LoadWeather(
        location: const Location(
          id: 'island_wide',
          name: 'Sri Lanka',
          country: 'Sri Lanka',
          latitude: 7.8731,
          longitude: 80.7718,
        ),
      ),
    );

  void _onToggleChanged(bool isNational) {
    setState(() => _isIslandWide = isNational);
    if (isNational) {
      _weatherBloc.add(
        LoadWeather(
          location: const Location(
            id: 'island_wide',
            name: 'Sri Lanka',
            country: 'Sri Lanka',
            latitude: 7.8731,
            longitude: 80.7718,
          ),
        ),
      );
    } else {
      _weatherBloc.add(const LoadWeather(useGps: true));
    }
  }

  @override
  void dispose() {
    _weatherBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _weatherBloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              NationalLocalToggle(
                isNational: _isIslandWide,
                onChanged: _onToggleChanged,
              ),
              Expanded(child: _buildTimelineContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context) {
    return Column(
      children: [
        // SOS alert header — pinned above the timeline list.
        BlocBuilder<AlertBloc, AlertState>(
          builder: (context, alertState) {
            if (alertState is AlertLoaded && alertState.alerts.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...alertState.alerts.map((a) => SosAlertBanner(alert: a)),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Expanded(
          child: BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              final l10n = AppLocalizations.of(context);

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
                  districtName: state.location?.name,
                  realLatitude: state.location?.latitude,
                  realLongitude: state.location?.longitude,
                );
                return _buildTimelineList(context, events);
              }

              return Center(
                child: Text(
                  l10n.t('timeline.loading'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(BuildContext context, List<TimelineEvent> events) {
    final l10n = AppLocalizations.of(context);
    final grouped = _groupEventsByDate(events, l10n);

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
              l10n.t('timeline.noActiveAlerts'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('timeline.conditionsCalm'),
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
    final l10n = AppLocalizations.of(context);
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
                  onTap: () {
                    context.push('/timeline-event-detail', extra: event);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getEventTypeLabel(event.type, l10n),
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
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).t('timeline.info'),
                                      style: const TextStyle(
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

  String _getEventTypeLabel(String type, AppLocalizations l10n) {
    final alertType = SLAlertType.fromString(type);
    if (alertType != null) return alertType.fullLabel;

    switch (type) {
      case 'flood':
        return l10n.t('timeline.event.flood');
      case 'landslide':
        return l10n.t('timeline.event.landslide');
      case 'cyclone':
        return l10n.t('timeline.event.cyclone');
      case 'lightning':
        return l10n.t('timeline.event.lightning');
      case 'coastal':
      case 'coastalWarning':
        return l10n.t('timeline.event.coastal');
      case 'tsunami':
        return l10n.t('timeline.event.tsunami');
      case 'earthquake':
        return l10n.t('timeline.event.earthquake');
      default:
        return l10n.t('timeline.info');
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

  List<_DateGroup> _groupEventsByDate(
    List<TimelineEvent> events,
    AppLocalizations l10n,
  ) {
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
        label = l10n.t('timeline.today');
      } else if (eventDate == yesterday) {
        label = l10n.t('timeline.yesterday');
      } else if (eventDate == tomorrow) {
        label = l10n.t('timeline.tomorrow');
      } else {
        const weekdayKeys = [
          'timeline.weekday.mon',
          'timeline.weekday.tue',
          'timeline.weekday.wed',
          'timeline.weekday.thu',
          'timeline.weekday.fri',
          'timeline.weekday.sat',
          'timeline.weekday.sun',
        ];

        final dayKey = weekdayKeys[event.time.weekday - 1];
        label = '${l10n.t(dayKey)} ${event.time.month}/${event.time.day}';
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
