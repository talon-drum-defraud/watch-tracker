import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a repeating reminder for a watch.
  /// [intervalHours] — how many hours between reminders.
  /// Pass 0 or call cancelWatchReminder to disable.
  Future<void> scheduleWatchReminder({
    required String watchId,
    required String watchName,
    required int intervalHours,
  }) async {
    await init();
    await cancelWatchReminder(watchId); // always clear existing first
    if (intervalHours <= 0) return;

    final notifId = watchId.hashCode.abs() % 100000;
    const androidDetails = AndroidNotificationDetails(
      'watch_reminders',
      'Watch Check Reminders',
      channelDescription: 'Reminders to log watch accuracy readings',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final scheduledTime = tz.TZDateTime.now(tz.local)
        .add(Duration(hours: intervalHours));

    // For daily or sub-daily: use repeating scheduled notification
    await _plugin.zonedSchedule(
      notifId,
      '⌚ Time to check $watchName',
      'Tap to log a new accuracy reading',
      scheduledTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: intervalHours == 24
          ? DateTimeComponents.time
          : null,
    );
  }

  Future<void> cancelWatchReminder(String watchId) async {
    await init();
    await _plugin.cancel(watchId.hashCode.abs() % 100000);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
