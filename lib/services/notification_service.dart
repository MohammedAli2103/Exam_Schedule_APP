import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/study_session.dart';

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
  Future<void> scheduleSessionNotifications({
    required StudySession session,
    int warningMinutes = 15,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();

    // Notification 1: At session start
    if (session.startTime.isAfter(now)) {
      final startNotificationId = session.id.hashCode;
      
      await _notificationsPlugin.zonedSchedule(
        startNotificationId,
        "Time to Study!",
        "It's time to study ${session.subjectName ?? 'your subject'} (${session.studyType}).",
        tz.TZDateTime.from(session.startTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_start_channel',
            'Study Reminders',
            channelDescription: 'Notifications for study sessions',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: session.id,
      );
    }

    // Notification 2: 15 minutes before session
    final warningTime = session.startTime.subtract(Duration(minutes: warningMinutes));
    if (warningTime.isAfter(now)) {
      final warningNotificationId = session.id.hashCode + 1;
      
      await _notificationsPlugin.zonedSchedule(
        warningNotificationId,
        "Upcoming Session",
        "${session.subjectName ?? 'Subject'} ${session.studyType} starts in $warningMinutes minutes.",
        tz.TZDateTime.from(warningTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_warning_channel',
            'Upcoming Session Warnings',
            channelDescription: 'Notifications warning about upcoming sessions',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: session.id,
      );
    }
  }

  /// Cancel all scheduled notifications for a study session.
  Future<void> cancelSessionNotifications(String sessionId) async {
    if (!_isInitialized) await initialize();

    final hash = sessionId.hashCode;
    await _notificationsPlugin.cancel(hash);     // Start session notification
    await _notificationsPlugin.cancel(hash + 1); // 15-minute warning
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notificationsPlugin.cancelAll();
  }
}
