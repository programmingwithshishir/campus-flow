import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/routine_item.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'routine_reminders_channel_v2';
  static const String channelName = 'Routine Reminders';
  static const String channelDesc = 'Audible reminder alerts for scheduled routines';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize time zones
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone()
            .timeout(const Duration(seconds: 1));
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (tzError) {
        debugPrint('Failed to set local timezone ($tzError), falling back to UTC');
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }

      // 2. Setup Android and iOS initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin
          .initialize(
            settings: initSettings,
            onDidReceiveNotificationResponse: (response) {
              debugPrint('Notification clicked with payload: ${response.payload}');
            },
          )
          .timeout(const Duration(seconds: 1));

      // 3. Create high priority notification channel for Android with sound enabled
      try {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // Remove old channel so Android does not reuse the previous silent channel settings
          try {
            await androidImplementation.deleteNotificationChannel(channelId: 'routine_priority_channel');
          } catch (_) {}

          await androidImplementation
              .createNotificationChannel(
                const AndroidNotificationChannel(
                  channelId,
                  channelName,
                  description: channelDesc,
                  importance: Importance.max,
                  playSound: true,
                  enableVibration: true,
                  showBadge: true,
                  audioAttributesUsage: AudioAttributesUsage.notification,
                ),
              )
              .timeout(const Duration(seconds: 1));
        }
      } catch (_) {}

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted =
              await androidImplementation.requestNotificationsPermission();
          try {
            await androidImplementation.requestExactAlarmsPermission();
          } catch (_) {}
          return granted ?? false;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          final granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  NotificationDetails _getPriorityNotificationDetails() {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      silent: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      ticker: 'Reminder',
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  int _getNotificationId(String routineId, int weekday) {
    // Generate positive stable 32-bit integer ID for routine + weekday combination
    final base = routineId.hashCode.abs() % 100000;
    return (base * 10) + weekday;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    // If day doesn't match or time has already passed today, advance day by day
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleRoutine(RoutineItem routine) async {
    try {
      await cancelRoutineNotifications(routine);

      if (!routine.isEnabled || routine.days.isEmpty) {
        return;
      }

      final details = _getPriorityNotificationDetails();

      for (final weekday in routine.days) {
        final notificationId = _getNotificationId(routine.id, weekday);
        final scheduledDate =
            _nextInstanceOfWeekdayTime(weekday, routine.hour, routine.minute);

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'Reminder',
          body: routine.name,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: routine.id,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling routine notifications: $e');
    }
  }

  Future<void> cancelRoutineNotifications(RoutineItem routine) async {
    try {
      for (int weekday = 1; weekday <= 7; weekday++) {
        final notificationId = _getNotificationId(routine.id, weekday);
        await _notificationsPlugin.cancel(id: notificationId);
      }
    } catch (e) {
      debugPrint('Error canceling routine notifications: $e');
    }
  }

  Future<void> rescheduleAllRoutines(List<RoutineItem> routines) async {
    for (final routine in routines) {
      await scheduleRoutine(routine);
    }
  }
}
