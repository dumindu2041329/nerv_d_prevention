import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/local/hive/hive_service.dart';
import '../../domain/entities/alert.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final HiveService _hiveService;

  LocalNotificationService({required HiveService hiveService})
    : _hiveService = hiveService;

  Future<void> init() async {
    // Android initialization settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (no-op for Android-focused app,
    // still required for plugin initialization).
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      // For now we do not handle notification taps.
    );
  }

  Future<String?> _getLastNotifiedAlertId() {
    return _hiveService.getSetting<String>('last_sos_notification_id');
  }

  Future<void> _setLastNotifiedAlertId(String id) {
    return _hiveService.setSetting('last_sos_notification_id', id);
  }

  /// Shows a local push-style notification when a new SOS alert appears.
  ///
  /// Uses the most severe alert (first in the provided list).
  Future<void> notifyIfNewSOSAlert(List<Alert> sortedAlerts) async {
    if (sortedAlerts.isEmpty) return;

    final alert = sortedAlerts.first;
    final lastId = await _getLastNotifiedAlertId();
    if (alert.id == lastId) return;

    // Mark first to avoid duplicate notifications while showing.
    await _setLastNotifiedAlertId(alert.id);

    await showSOSNotification(alert);
  }

  Future<void> showSOSNotification(Alert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_alerts_channel',
      'SOS Alerts',
      channelDescription: 'Local notifications for SOS/disaster alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      // Use a stable id derived from alert id hash
      id: alert.id.hashCode & 0x7fffffff,
      title: alert.headline,
      body: alert.description,
      notificationDetails: notificationDetails,
      payload: alert.id,
    );
  }
}
