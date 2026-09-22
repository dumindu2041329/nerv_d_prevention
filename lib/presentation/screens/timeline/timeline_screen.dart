import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/deck_header.dart';

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<WeatherBloc, WeatherState>(
                builder: (context, state) {
                  return DeckHeader(
                    title: 'Timeline',
                    eyebrowText: 'SRI LANKA · 72-HR WATCH',
                    subtitle: _isIslandWide
                        ? 'Island-wide'
                        : 'Current location',
                    posture: _postureFromWeather(state),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: NationalLocalToggle(
                  isNational: _isIslandWide,
                  onChanged: _onToggleChanged,
                ),
              ),
              Expanded(child: _buildTimelineContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  SeverityLevel _postureFromWeather(WeatherState state) {
    if (state is! WeatherLoaded) return SeverityLevel.calm;
    final events = WeatherAlertDeriver.deriveTimelineEvents(
      state.weatherData,
      districtName: state.location?.name,
    );
    return NervStyles.postureOf(events.map((e) => e.severity).toList());
  }

  Widget _buildTimelineContent(BuildContext context) {
    final nerv = context.nerv;

    // One scroll view for the whole screen: SOS banners at the top,
    // 72-hour timeline below. No nested scrollables.
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Active SOS alerts ──
        BlocBuilder<AlertBloc, AlertState>(
          builder: (context, alertState) {
            if (alertState is AlertLoaded && alertState.alerts.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

        // ── Timeline events ──
        BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);

            if (state is WeatherLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 96),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (state is WeatherError) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: nerv.body,
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
              return _buildTimelineBody(context, events);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 96),
              child: Center(
                child: Text(
                  l10n.t('timeline.loading'),
                  style: nerv.dataLabel,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Non-scrolling timeline body — rendered inside the screen's single
  /// [ListView]. Empty state shows the "calm" placeholder in line.
  Widget _buildTimelineBody(BuildContext context, List<TimelineEvent> events) {
    final l10n = AppLocalizations.of(context);
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final grouped = _groupEventsByDate(events, l10n);

    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Eyebrow('NO ACTIVE ALERTS'),
            const SizedBox(height: 12),
            Text(
              l10n.t('timeline.noActiveAlerts'),
              style: nerv.headline,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('timeline.conditionsCalm'),
              style: nerv.body.copyWith(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in grouped) _buildDateGroup(context, group, grouped),
      ],
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
        _buildDateSeparator(context, group.label),
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

  Widget _buildDateSeparator(BuildContext context, String label) {
    final nerv = context.nerv;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: nerv.hairline),
          ),
        ],
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
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final color = event.severity.color;
    final isLifted = event.isLifted;
    final lineColor = onSurface.withValues(alpha: 0.15);

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column (tabular data)
            SizedBox(
              width: 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  DateTimeUtils.formatTime(event.time),
                  style: nerv.numeralSmall(size: 13).copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Severity rail — 2px tick + connector line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  SizedBox(
                    height: isFirst ? 10 : 8,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 1.5,
                        height: 8,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),
                  ),
                  // Severity marker (square tick, echoing the state line)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isLifted
                          ? onSurface.withValues(alpha: 0.25)
                          : color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
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
                                Expanded(
                                  child: Text(
                                    _getEventTypeLabel(event.type, l10n)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: isLifted
                                          ? onSurface.withValues(alpha: 0.4)
                                          : color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                      color: onSurface.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).t('timeline.info'),
                                      style: TextStyle(
                                        color: onSurface.withValues(alpha: 0.6),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.title,
                              style: TextStyle(
                                color: isLifted
                                    ? onSurface.withValues(alpha: 0.35)
                                    : onSurface.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: onSurface.withValues(alpha: 0.3),
                        size: 20,
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
