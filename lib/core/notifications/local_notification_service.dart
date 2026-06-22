import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/local/hive/hive_service.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/timeline_event.dart';
import '../constants/app_colors.dart';

/// Wraps `flutter_local_notifications` to surface real OS-level
/// notifications for high-severity disaster alerts.
///
/// Lifecycle:
/// 1. `init()` is called once at app startup from [initDependencies].
/// 2. When the user toggles notifications on in settings,
///    [requestPermissions] is invoked to ask the OS for permission.
/// 3. After every alert load/refresh, the AlertBloc calls
///    [notifyIfNewSOSAlert] with the freshly fetched alert list.
///    This method self-checks the `notifications_enabled` setting
///    so turning the toggle off immediately silences future alerts.
///
/// Already-shown alert IDs are tracked in the `settings` Hive box so
/// the same alert doesn't spam the user across app restarts. The
/// list is capped at [_kMaxTrackedIds] to keep storage bounded.
class LocalNotificationService {
  LocalNotificationService({required HiveService hiveService})
    : _hiveService = hiveService,
      _plugin = FlutterLocalNotificationsPlugin();

  final HiveService _hiveService;
  final FlutterLocalNotificationsPlugin _plugin;

  // Android notification channel for SOS / disaster alerts.
  static const String _sosChannelId = 'sos_alerts';
  static const String _sosChannelName = 'SOS Alerts';
  static const String _sosChannelDescription =
      'Critical and emergency disaster alerts';

  // Settings-box keys.
  static const String _kNotificationsEnabledKey = 'notifications_enabled';
  static const String _kNotifiedIdsKey = 'notified_alert_ids';
  static const String _kNotifiedTimelineIdsKey = 'notified_timeline_ids';
  static const String _kNotifiedCurrentConditionIdsKey =
      'notified_current_condition_ids';
  static const int _kMaxTrackedIds = 200;

  /// Fixed ID for the one-shot welcome notification fired when the user
  /// toggles notifications ON. Stays the same so the same slot is
  /// overwritten on subsequent toggles.
  static const int _kWelcomeNotificationId = 999999;

  /// Android channel for timeline-derived forecast events.
  static const String _timelineChannelId = 'timeline_alerts';
  static const String _timelineChannelName = 'Timeline Alerts';
  static const String _timelineChannelDescription =
      'Upcoming severe weather and disaster timeline events';

  /// Android channel for current-conditions digest notifications.
  static const String _currentChannelId = 'current_conditions';
  static const String _currentChannelName = 'Current Conditions';
  static const String _currentChannelDescription =
      'Daily weather digest and active-alert summary';

  /// True if `init()` has completed successfully.
  bool _initialized = false;

  /// Configure platform-specific settings. Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // We request permission explicitly via [requestPermissions]
      // when the user opts in from Settings — never on startup.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Pre-create the Android channels so first-alert delivery is instant.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _sosChannelId,
          _sosChannelName,
          description: _sosChannelDescription,
          importance: Importance.max,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _timelineChannelId,
          _timelineChannelName,
          description: _timelineChannelDescription,
          importance: Importance.high,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _currentChannelId,
          _currentChannelName,
          description: _currentChannelDescription,
          importance: Importance.defaultImportance,
        ),
      );
    }

    _initialized = true;
  }

  /// Ask the OS for notification permission. Returns `true` if granted.
  ///
  /// On Android 13+ this triggers the runtime POST_NOTIFICATIONS prompt.
  /// On iOS this triggers the system permission alert. Falls back to
  /// `permission_handler` for additional reliability.
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    bool granted = false;

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      granted =
          await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final androidGranted =
          await androidImpl.requestNotificationsPermission() ?? false;
      granted = granted || androidGranted;
    }

    // permission_handler covers edge cases where the plugin's own
    // request is unavailable or has been denied permanently.
    final status = await Permission.notification.request();
    if (status.isGranted || status.isLimited) {
      granted = true;
    }

    return granted;
  }

  /// Fire a one-shot confirmation notification. Useful to prove the
  /// OS-level notification pipeline actually delivers after the user
  /// toggles notifications on in Settings — a real on-device toast
  /// rather than a silent setting flip.
  Future<void> showWelcomeNotification() async {
    if (!_initialized) await init();
    if (!await _areNotificationsEnabledInApp()) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timelineChannelId,
        _timelineChannelName,
        channelDescription: _timelineChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF00BCD4),
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'timeline_alerts',
      ),
    );

    await _plugin.show(
      id: _kWelcomeNotificationId,
      title: 'Notifications enabled',
      body:
          'You will be alerted when severe weather or disaster alerts '
          'are detected for your location.',
      notificationDetails: details,
      payload: 'welcome',
    );
  }

  /// Inspect the in-app `notifications_enabled` toggle.
  Future<bool> _areNotificationsEnabledInApp() async {
    final enabled = await _hiveService.getSetting<bool>(
      _kNotificationsEnabledKey,
    );
    // Default to enabled on first run so users see alerts they
    // explicitly asked for via the SOS button.
    return enabled ?? true;
  }

  /// Public entry point invoked by [AlertBloc] after every fetch.
  ///
  /// Surfaces a system notification for each Critical/Emergency alert
  /// the user hasn't already been notified about. Idempotent across
  /// app restarts thanks to Hive-backed dedup.
  Future<void> notifyIfNewSOSAlert(List<Alert> alerts) async {
    if (!_initialized) await init();
    if (!await _areNotificationsEnabledInApp()) return;

    final alreadyNotified = await _readNotifiedIds();

    // Most-severe first so the highest-priority alert wins the
    // heads-up notification slot if the OS throttles simultaneous ones.
    final sorted = [...alerts]
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));

    final newlyNotified = <String>{};
    for (final alert in sorted) {
      // Notify for Critical, Emergency, and Warning SOS alerts. Warning
      // is included so users in genuinely bad conditions see something
      // on their device even when no top-tier alert exists.
      if (alert.severity != SeverityLevel.critical &&
          alert.severity != SeverityLevel.emergency &&
          alert.severity != SeverityLevel.warning) {
        continue;
      }
      if (alreadyNotified.contains(alert.id)) continue;

      try {
        await _showNotification(alert);
        newlyNotified.add(alert.id);
      } catch (_) {
        // Don't block the UI thread on a single failed notification.
      }
    }

    if (newlyNotified.isNotEmpty) {
      await _writeNotifiedIds({...alreadyNotified, ...newlyNotified});
    }
  }

  Future<Set<String>> _readNotifiedIds() async {
    final raw = await _hiveService.getSetting<List<dynamic>>(_kNotifiedIdsKey);
    if (raw == null) return <String>{};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _writeNotifiedIds(Set<String> ids) async {
    // Cap the list so long-running installs don't grow unbounded.
    final ordered = ids.toList();
    final trimmed = ordered.length > _kMaxTrackedIds
        ? ordered.sublist(ordered.length - _kMaxTrackedIds)
        : ordered;
    await _hiveService.setSetting(_kNotifiedIdsKey, trimmed);
  }

  Future<Set<String>> _readNotifiedTimelineIds() async {
    final raw = await _hiveService.getSetting<List<dynamic>>(
      _kNotifiedTimelineIdsKey,
    );
    if (raw == null) return <String>{};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _writeNotifiedTimelineIds(Set<String> ids) async {
    final ordered = ids.toList();
    final trimmed = ordered.length > _kMaxTrackedIds
        ? ordered.sublist(ordered.length - _kMaxTrackedIds)
        : ordered;
    await _hiveService.setSetting(_kNotifiedTimelineIdsKey, trimmed);
  }

  /// Public entry point invoked by [WeatherBloc] after every fresh
  /// weather load. Surfaces a system notification for each upcoming
  /// [Critical], [Emergency] or [Warning] timeline event the user
  /// hasn't already been notified about.
  ///
  /// Because timeline events are re-derived on every load (their `id`
  /// resets), we compute a stable dedup key from the event's content
  /// (`type + location + severity + day-bucket`) so the same forecast
  /// slot doesn't re-notify across app restarts or pull-to-refreshes.
  ///
  /// Past events and "lifted" (resolved) events are ignored — only
  /// upcoming threats are surfaced.
  Future<void> notifyIfNewTimelineEvent(List<TimelineEvent> events) async {
    if (!_initialized) await init();
    if (!await _areNotificationsEnabledInApp()) return;

    final alreadyNotified = await _readNotifiedTimelineIds();
    final now = DateTime.now();

    // Most-severe first so the highest-priority event wins the
    // heads-up slot if the OS throttles simultaneous notifications.
    final sorted = [...events]
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));

    final newlyNotified = <String>{};
    for (final event in sorted) {
      if (event.isLifted) continue;
      if (!event.time.isAfter(now)) continue;
      // Notify for any non-Calm timeline event so users see a real
      // device notification whenever the weather has something to say.
      if (event.severity == SeverityLevel.calm) continue;

      final dedupKey = _timelineDedupKey(event);
      if (alreadyNotified.contains(dedupKey)) continue;

      try {
        await _showTimelineNotification(event);
        newlyNotified.add(dedupKey);
      } catch (_) {
        // Don't block the UI thread on a single failed notification.
      }
    }

    if (newlyNotified.isNotEmpty) {
      await _writeNotifiedTimelineIds({...alreadyNotified, ...newlyNotified});
    }
  }

  /// Build a stable dedup key for a [TimelineEvent]. Bucket by day so
  /// a forecast that shifts by an hour still dedups, but a forecast
  /// that's been meaningfully updated (different day) counts as new.
  String _timelineDedupKey(TimelineEvent event) {
    final loc = (event.location ?? '').trim().toLowerCase();
    final t = event.time;
    final dayBucket =
        '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';
    return '${event.type}|${event.severity.name}|$loc|$dayBucket';
  }

  Future<void> _showTimelineNotification(TimelineEvent event) async {
    final timeLabel = _formatTimelineTime(event.time);
    final severityPrefix = event.severity.label;
    final title = '[$severityPrefix] ${event.title}';
    final descriptionSnippet = event.description ?? '';
    final body = descriptionSnippet.isNotEmpty
        ? '$descriptionSnippet\nExpected around $timeLabel'
        : 'Expected around $timeLabel';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timelineChannelId,
        _timelineChannelName,
        channelDescription: _timelineChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: event.severity.color,
        ticker: title,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'timeline_alerts',
      ),
    );

    await _plugin.show(
      id: _timelineNotificationId(event),
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'timeline:${event.id}',
    );
  }

  /// Hash a timeline event into a stable notification ID.
  /// `0` and low positive ints collide with the SOS channel — add an
  /// offset so timeline notifications get a distinct numeric space.
  int _timelineNotificationId(TimelineEvent event) {
    final raw = _timelineDedupKey(event).hashCode;
    return (raw & 0x7FFFFFFF) + 1000000;
  }

  String _formatTimelineTime(DateTime t) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${months[t.month - 1]} ${t.day}, ${two(t.hour)}:${two(t.minute)}';
  }

  /// Surface a single digest notification summarising the current
  /// weather and any non-calm derived alerts. Designed to give users
  /// regular, low-noise device notifications when conditions are
  /// non-trivial — proving the pipeline works even on a calm day.
  ///
  /// Dedups by day so the same digest doesn't spam the user.
  Future<void> notifyCurrentConditionsDigest({
    required String locationName,
    required double temperatureC,
    required String conditionsLabel,
    required int nonCalmAlertCount,
    required String? topAlertHeadline,
  }) async {
    if (!_initialized) await init();
    if (!await _areNotificationsEnabledInApp()) return;
    if (nonCalmAlertCount == 0 && topAlertHeadline == null) return;

    final today = DateTime.now();
    final dedupKey =
        '${today.year}-${today.month}-${today.day}|$locationName';
    final alreadyNotified = await _readNotifiedCurrentConditionIds();
    if (alreadyNotified.contains(dedupKey)) return;

    final tempText = '${temperatureC.toStringAsFixed(0)}°C';
    final String body;
    final String title;
    if (nonCalmAlertCount > 0) {
      title = 'Weather alert for $locationName';
      final alertsSuffix = nonCalmAlertCount == 1
          ? '1 active alert'
          : '$nonCalmAlertCount active alerts';
      body =
          '$tempText, $conditionsLabel. $alertsSuffix'
          '${topAlertHeadline == null ? '' : ': $topAlertHeadline'}';
    } else {
      title = 'Weather update · $locationName';
      body = '$tempText, $conditionsLabel. Stay safe.';
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _currentChannelId,
        _currentChannelName,
        channelDescription: _currentChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: const Color(0xFF00BCD4),
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
        threadIdentifier: 'current_conditions',
      ),
    );

    await _plugin.show(
      id: _digestNotificationId(today, locationName),
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'digest:$locationName',
    );

    await _writeNotifiedCurrentConditionIds({...alreadyNotified, dedupKey});
  }

  Future<Set<String>> _readNotifiedCurrentConditionIds() async {
    final raw = await _hiveService.getSetting<List<dynamic>>(
      _kNotifiedCurrentConditionIdsKey,
    );
    if (raw == null) return <String>{};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _writeNotifiedCurrentConditionIds(Set<String> ids) async {
    final ordered = ids.toList();
    final trimmed = ordered.length > _kMaxTrackedIds
        ? ordered.sublist(ordered.length - _kMaxTrackedIds)
        : ordered;
    await _hiveService.setSetting(_kNotifiedCurrentConditionIdsKey, trimmed);
  }

  /// Stable numeric ID for a daily digest so it overwrites itself
  /// rather than stacking on every refresh.
  int _digestNotificationId(DateTime t, String locationName) {
    final dayBucket = t.year * 10000 + t.month * 100 + t.day;
    return (dayBucket + locationName.hashCode.abs()) & 0x3FFFFFFF;
  }

  Future<void> _showNotification(Alert alert) async {
    final body = alert.description.isNotEmpty
        ? alert.description
        : (alert.location.isNotEmpty ? alert.location : 'Disaster alert');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _sosChannelId,
        _sosChannelName,
        channelDescription: _sosChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        color: alert.severity.color,
        ticker: alert.headline,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        threadIdentifier: 'sos_alerts',
      ),
    );

    await _plugin.show(
      id: alert.id.hashCode,
      title: alert.headline,
      body: body,
      notificationDetails: details,
      payload: alert.id,
    );
  }
}
