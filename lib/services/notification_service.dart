import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Ensure timezone is ALWAYS set - with fallback to UTC
    try {
       const String timeZoneName = 'Asia/Kolkata'; 
       tz.setLocalLocation(tz.getLocation(timeZoneName));
       print("Local timezone set to: $timeZoneName");
    } catch (e) {
      print("Could not set Asia/Kolkata timezone: $e");
      try {
        // Fallback to UTC to prevent crashes
        tz.setLocalLocation(tz.getLocation('UTC'));
        print("Fallback: Using UTC timezone");
      } catch (e2) {
        print("CRITICAL: Could not set any timezone: $e2");
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Explicitly create the channel to ensure high priority is registered
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_notification_channel_v3',
          'Daily Notifications V3',
          description: 'Daily status reminder',
          importance: Importance.max,
          playSound: true,
        ),
      );
    }
  }

  Future<void> requestPermissions() async {
     await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyNotification({TimeOfDay? time}) async {
    final prefs = await SharedPreferences.getInstance();
    TimeOfDay scheduledTime;

    if (time != null) {
      // Case 1: User sets a new time -> Save it
      scheduledTime = time;
      await prefs.setInt('notif_hour', scheduledTime.hour);
      await prefs.setInt('notif_minute', scheduledTime.minute);
    } else {
      // Case 2: App startup -> Load saved time (don't overwrite!)
      final int hour = prefs.getInt('notif_hour') ?? 7;
      final int minute = prefs.getInt('notif_minute') ?? 0;
      scheduledTime = TimeOfDay(hour: hour, minute: minute);
    }


    print("Scheduling daily notification for ${scheduledTime.hour}:${scheduledTime.minute}");

    // Use a simple generic message to avoid database fetch crashes
    // The actual content will be generated when notification shows
    String bodyText = 'Tap to check your pending orders and deliveries';


    print("Scheduling request for: $scheduledTime");
    final nextTime = _nextInstanceOfTime(scheduledTime);
    print("Next instance calculated: $nextTime");

    try {
      // Cancel any existing notification first
      await flutterLocalNotificationsPlugin.cancel(0);
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID
        'AJ Stocks Daily Update',
        bodyText, // Dynamic Body
        nextTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification_channel_v3',
            'Daily Notifications V3',
            channelDescription: 'Daily status reminder',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(bodyText),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder, 
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Same as test - more reliable
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // REMOVED matchDateTimeComponents to make it ONE-TIME instead of repeating
        // This is more reliable on devices that kill repeating alarms
      );
      print("Notification successfully scheduled (AlarmClock Mode, One-Time) for $nextTime");
      
      // IMPORTANT: Show a reminder that they need to open app daily to reschedule
      await showInstantNotification(
        title: "Notification Scheduled",
        body: "Set for ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')} tomorrow. Open app daily to keep it active!",
      );
      
      // OPTIONAL: Immediate confirmation for the user to prove logic ran
      // await showInstantNotification(
      //  title: "Schedule Updated", 
      //  body: "Daily reminder set for ${scheduledTime.format(context)}"
      // ); 
      
    } catch (e) {
      print("CRITICAL ERROR Scheduling Notification: $e");
      // Fallback to simple show just to prove it works? No, scheduled is needed.
    }
  }

  Future<String> scheduleTestIn30Seconds() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 30));
      
      print("SIMPLE TEST: Now is $now");
      print("SIMPLE TEST: Scheduling for $scheduledTime (30 seconds from now)");
      
      // Use the simplest possible scheduling mode
      await flutterLocalNotificationsPlugin.zonedSchedule(
        888,
        'TEST in 30 seconds',
        'Success! Time: ${DateTime.now()}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification_channel_v3',
            'Daily Notifications V3',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Simpler mode
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print("SIMPLE TEST: Scheduled successfully");
      return "OK: Scheduled for $scheduledTime";
    } catch (e, stackTrace) {
      print("SIMPLE TEST ERROR: $e");
      print("STACK: $stackTrace");
      return "ERROR: $e";
    }
  }


  Future<void> showInstantNotification({required String title, required String body}) async {
    await flutterLocalNotificationsPlugin.show(
      999, // Unique ID for test
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification_channel_v3', // Reuse same channel to test config
          'Daily Notifications V3',
          channelDescription: 'Daily status reminder',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
    );
  }

  Future<TimeOfDay> getSavedNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_hour') ?? 7;
    final minute = prefs.getInt('notif_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
