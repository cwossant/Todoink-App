import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../models/task_status.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 9000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: initializationSettings);
    _isInitialized = true;
  }

  /// Best-effort check for whether notifications are currently enabled.
  ///
  /// Returns:
  /// - `true` if enabled
  /// - `false` if disabled
  /// - `null` if the platform/plugin version doesn't expose a reliable check
  Future<bool?> areNotificationsEnabled() async {
    await init();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await (androidImpl as dynamic?)?.areNotificationsEnabled();
      if (enabled is bool) return enabled;
    } catch (_) {
      // Ignore; fall through to iOS check.
    }

    try {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final permissions = await (iosImpl as dynamic?)?.checkPermissions();
      if (permissions is bool) return permissions;

      // Some plugin versions return a permissions object.
      if (permissions != null) {
        final alert = (permissions as dynamic).alert;
        final badge = (permissions as dynamic).badge;
        final sound = (permissions as dynamic).sound;
        if (alert is bool || badge is bool || sound is bool) {
          return (alert == true) || (badge == true) || (sound == true);
        }
      }
    } catch (_) {
      // Ignore.
    }

    return null;
  }

  /// Requests notification permission only if not already enabled.
  ///
  /// Returns `true` if notifications are enabled after the call.
  Future<bool> ensureNotificationPermission() async {
    final enabledBefore = await areNotificationsEnabled();
    if (enabledBefore == true) return true;

    await requestPermissions();

    final enabledAfter = await areNotificationsEnabled();
    return enabledAfter ?? false;
  }

  Future<void> requestPermissions() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Task and daily routine reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  int _notificationIdForTaskId(String taskId) {
    // Task IDs are UUIDs; use a stable, bounded int derived from the hex.
    final hex = taskId.replaceAll('-', '');
    if (hex.length < 8) return taskId.codeUnits.fold(0, (a, b) => a + b);

    final first32Bits = int.parse(hex.substring(0, 8), radix: 16);
    return first32Bits & 0x7FFFFFFF;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final scheduled = _nextInstanceOfTime(time);

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Daily routine',
      body: 'Check your tasks for today.',
      scheduledDate: scheduled,
      notificationDetails: _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.time == null) return;
    if (task.status == TaskStatus.done) return;

    final scheduled = tz.TZDateTime(
      tz.local,
      task.date.year,
      task.date.month,
      task.date.day,
      task.time!.hour,
      task.time!.minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) return;

    final timeLabel = DateFormat('h:mm a').format(
      DateTime(2024, 1, 1, task.time!.hour, task.time!.minute),
    );

    await _plugin.zonedSchedule(
      id: _notificationIdForTaskId(task.id),
      title: task.title,
      body: 'Reminder at $timeLabel',
      scheduledDate: scheduled,
      notificationDetails: _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(id: _notificationIdForTaskId(taskId));
  }
}
