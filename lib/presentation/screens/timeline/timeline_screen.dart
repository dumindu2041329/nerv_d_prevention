import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/timeline_event.dart';
import '../../../core/utils/date_time_utils.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _selectedFilter = 'all';

  final List<TimelineFilterData> _filters = [
    TimelineFilterData(id: 'all', label: 'All'),
    TimelineFilterData(id: 'earthquake', label: 'Earthquake'),
    TimelineFilterData(id: 'tsunami', label: 'Tsunami'),
    TimelineFilterData(id: 'weather', label: 'Weather'),
    TimelineFilterData(id: 'volcano', label: 'Volcano'),
    TimelineFilterData(id: 'j-alert', label: 'J-Alert'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterChips(context),
            Expanded(
              child: _buildTimelineList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space5,
        AppSpacing.space4,
        AppSpacing.space5,
        AppSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              onTap: () => _showFilterSheet(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Filter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space3,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = filter.id == _selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = filter.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerTheme.color ?? Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context) {
    final events = _getDemoEvents();

    if (events.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'No events',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              'No events to display',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventItem(context, event, index == 0);
      },
    );
  }

  Widget _buildEventItem(BuildContext context, TimelineEvent event, bool isFirst) {
    final theme = Theme.of(context);
    final isLifted = event.isLifted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateTimeUtils.formatTime(event.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLifted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  DateTimeUtils.formatDateShort(event.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLifted
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                      : event.severity.color,
                  border: Border.all(
                    color: isLifted
                        ? theme.dividerTheme.color ?? Colors.grey
                        : event.severity.color,
                    width: 2,
                  ),
                ),
              ),
              if (!isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.dividerTheme.color?.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.space4),
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isLifted
                      ? theme.dividerTheme.color?.withValues(alpha: 0.3) ?? Colors.grey
                      : event.severity.color.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space2),
                        decoration: BoxDecoration(
                          color: (isLifted
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                                  : event.severity.color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          _getEventIcon(event.type),
                          size: 16,
                          color: isLifted
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : event.severity.color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: isLifted ? TextDecoration.lineThrough : null,
                                color: isLifted
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (event.location != null)
                              Text(
                                event.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isLifted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: AppSpacing.space1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            'Lifted',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      event.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TimelineEvent> _getDemoEvents() {
    final now = DateTime.now();
    return [
      TimelineEvent(
        id: '1',
        type: 'weather',
        title: 'Heavy Rain Warning',
        description: 'Risk of localized heavy rain in Western Province',
        location: 'Western Province',
        severity: SeverityLevel.warning,
        time: now.subtract(const Duration(hours: 2)),
      ),
      TimelineEvent(
        id: '2',
        type: 'weather',
        title: 'Strong Wind Advisory',
        description: 'Caution for strong winds in Coastal Areas',
        location: 'Coastal Areas',
        severity: SeverityLevel.advisory,
        time: now.subtract(const Duration(hours: 5)),
      ),
      TimelineEvent(
        id: '3',
        type: 'earthquake',
        title: 'Earthquake Info',
        description: 'Epicenter depth 20km, Maximum intensity 3',
        location: 'Pacific Ocean',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(hours: 8)),
      ),
      TimelineEvent(
        id: '4',
        type: 'weather',
        title: 'Heavy Rain Warning Lifted',
        description: 'Heavy rain warning for Western Province has been lifted',
        location: 'Western Province',
        severity: SeverityLevel.info,
        time: now.subtract(const Duration(days: 1, hours: 3)),
        isLifted: true,
      ),
    ];
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: _filters.map((filter) {
                  final isSelected = filter.id == _selectedFilter;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter.id);
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.space4),
            ],
          ),
        );
      },
    );
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
}

class TimelineFilterData {
  final String id;
  final String label;

  const TimelineFilterData({
    required this.id,
    required this.label,
  });
}
