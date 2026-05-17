import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/timeline_event.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../widgets/national_local_toggle.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isNational = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            NationalLocalToggle(
              isNational: _isNational,
              onChanged: (val) => setState(() => _isNational = val),
            ),
            Expanded(
              child: _buildTimelineList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context) {
    final events = _getDemoEvents();
    final grouped = _groupEventsByDate(events);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return _buildDateGroup(context, group);
      },
    );
  }

  Widget _buildDateGroup(BuildContext context, _DateGroup group) {
    return Column(
      children: [
        // Date separator pill
        _buildDateSeparator(group.label),
        // Events in this group
        ...group.events.asMap().entries.map((entry) {
          final isFirst = entry.key == 0 && grouped.indexOf(group) == 0;
          final isLast = entry.key == group.events.length - 1 &&
              grouped.indexOf(group) == grouped.length - 1;
          return _buildEventItem(context, entry.value, isFirst, isLast);
        }),
      ],
    );
  }

  List<_DateGroup> get grouped => _groupEventsByDate(_getDemoEvents());

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
                  // Circle dot
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getEventIcon(event.type),
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6),
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
                            Text(
                              _getEventTypeLabel(event.type),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.title,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
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
    switch (type) {
      case 'earthquake':
        return 'Earthquake Info';
      case 'tsunami':
        return 'Tsunami Warning';
      case 'weather':
        return 'Weather Alert';
      case 'volcano':
        return 'Volcano Alert';
      case 'j-alert':
        return 'J-Alert';
      default:
        return 'Information';
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'earthquake':
        return Icons.public;
      case 'tsunami':
        return Icons.waves;
      case 'weather':
        return Icons.cloud;
      case 'volcano':
        return Icons.landscape;
      case 'j-alert':
        return Icons.campaign;
      default:
        return Icons.info;
    }
  }

  List<_DateGroup> _groupEventsByDate(List<TimelineEvent> events) {
    final Map<String, List<TimelineEvent>> groups = {};

    for (final event in events) {
      final now = DateTime.now();
      final eventDate = DateTime(event.time.year, event.time.month, event.time.day);
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      String label;
      if (eventDate == today) {
        label = 'Today';
      } else if (eventDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = '${event.time.month}/${event.time.day}';
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(event);
    }

    return groups.entries.map((e) => _DateGroup(e.key, e.value)).toList();
  }

  List<TimelineEvent> _getDemoEvents() {
    final now = DateTime.now();
    return [
      TimelineEvent(
        id: '1',
        type: 'earthquake',
        title: 'Off. Ibaraki (Int. 1)',
        description: 'Epicenter depth 50km, Magnitude 2.9',
        location: 'Off. Ibaraki',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(hours: 1)),
      ),
      TimelineEvent(
        id: '2',
        type: 'earthquake',
        title: 'Off. Iwate (Int. 1)',
        description: 'Epicenter depth 30km',
        location: 'Off. Iwate',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(hours: 9)),
      ),
      TimelineEvent(
        id: '3',
        type: 'earthquake',
        title: 'Off. Miyagi (Int. 2)',
        description: 'Epicenter depth 40km',
        location: 'Off. Miyagi',
        severity: SeverityLevel.advisory,
        time: now.subtract(const Duration(hours: 15)),
      ),
      TimelineEvent(
        id: '4',
        type: 'earthquake',
        title: 'Off. Sanriku (Int. 2)',
        description: 'Epicenter depth 10km',
        location: 'Off. Sanriku',
        severity: SeverityLevel.advisory,
        time: now.subtract(const Duration(hours: 18)),
      ),
      TimelineEvent(
        id: '5',
        type: 'earthquake',
        title: 'Kagoshima Satsuma (Int. 2)',
        description: 'Epicenter depth 10km',
        location: 'Kagoshima Satsuma',
        severity: SeverityLevel.advisory,
        time: now.subtract(const Duration(hours: 21)),
      ),
      TimelineEvent(
        id: '6',
        type: 'earthquake',
        title: 'Kagoshima Satsuma (Int. 1)',
        description: 'Epicenter depth 10km',
        location: 'Kagoshima Satsuma',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(hours: 22)),
      ),
      TimelineEvent(
        id: '7',
        type: 'earthquake',
        title: 'Eastern Shimane (Int. 1)',
        description: 'Epicenter depth 20km',
        location: 'Eastern Shimane',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(hours: 23)),
      ),
      // Yesterday's events
      TimelineEvent(
        id: '8',
        type: 'earthquake',
        title: 'Iriomotejima (Int. 1)',
        description: 'Epicenter depth 30km',
        location: 'Iriomotejima',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      TimelineEvent(
        id: '9',
        type: 'earthquake',
        title: 'Kii Channel (Int. 2)',
        description: 'Epicenter depth 15km',
        location: 'Kii Channel',
        severity: SeverityLevel.advisory,
        time: now.subtract(const Duration(days: 1, hours: 15)),
      ),
    ];
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

  const TimelineFilterData({
    required this.id,
    required this.label,
  });
}
