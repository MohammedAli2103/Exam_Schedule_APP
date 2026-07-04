import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/study_session.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final bool? androidGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final bool? iosGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  /// Schedule study notifications for a specific session.
  /// Schedules a 15-minute warning notification and a start time notification.
  /// Returns true if scheduling was successful, false otherwise.
  Future<bool> scheduleSessionNotifications({
    required StudySession session,
    int warningMinutes = 15,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();

      // Notification 1: At session start
      if (session.startTime.isAfter(now)) {
        final startNotificationId = session.id.hashCode;
        
        await _scheduleNotificationWithFallback(
          id: startNotificationId,
          title: "Time to Study!",
          body: "It's time to study ${session.subjectName ?? 'your subject'} (${session.studyType}).",
          scheduledDate: session.startTime,
          details: const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_start_channel',
              'Study Reminders',
              channelDescription: 'Notifications for study sessions',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: session.id,
        );
      }

      // Notification 2: 15 minutes before session
      final warningTime = session.startTime.subtract(Duration(minutes: warningMinutes));
      if (warningTime.isAfter(now)) {
        final warningNotificationId = session.id.hashCode + 1;
        
        await _scheduleNotificationWithFallback(
          id: warningNotificationId,
          title: "Upcoming Session",
          body: "${session.subjectName ?? 'Subject'} ${session.studyType} starts in $warningMinutes minutes.",
          scheduledDate: warningTime,
          details: const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_warning_channel',
              'Upcoming Session Warnings',
              channelDescription: 'Notifications warning about upcoming sessions',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: session.id,
        );
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint("Error scheduling notifications: $e\n$stackTrace");
      return false;
    }
  }

  /// Helper to attempt exact scheduling and fallback to inexact scheduling if exact alarms are not permitted.
  Future<void> _scheduleNotificationWithFallback({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    try {
      // 1. Attempt exact scheduling
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint("Exact alarms not permitted. Scheduling as inexact notification.");
        // 2. Fallback to inexact scheduling
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else {
        rethrow;
      }
    } catch (e) {
      if (e.toString().contains("exact_alarms_not_permitted") || e.toString().contains("Exact alarms are not permitted")) {
        debugPrint("Exact alarms not permitted (general exception). Scheduling as inexact notification.");
        // 2. Fallback to inexact scheduling
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Cancel all scheduled notifications for a study session.
  Future<void> cancelSessionNotifications(String sessionId) async {
    try {
      if (!_isInitialized) await initialize();

      final hash = sessionId.hashCode;
      await _notificationsPlugin.cancel(hash);     // Start session notification
      await _notificationsPlugin.cancel(hash + 1); // 15-minute warning
    } catch (e) {
      debugPrint("Error cancelling notifications: $e");
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) await initialize();
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("Error cancelling all notifications: $e");
    }
  }
}
