import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehnway/utils/app_logger.dart';

class DailyReminderService {
  static const _notificationId = 1600;
  static const _channelKey = 'vehnway_daily_reminder';
  static const _enabledKey = 'daily_reminder_enabled';
  static const _hourKey = 'daily_reminder_hour';
  static const _minuteKey = 'daily_reminder_minute';
  static final _notifications = AwesomeNotifications();

  static Future<void> initialize() async {
    try {
      await _ensureInitialized();
      final preferences = await SharedPreferences.getInstance();
      if (!(preferences.getBool(_enabledKey) ?? false)) {
        await _notifications.cancelSchedule(_notificationId);
        return;
      }

      final permissionGranted =
          await _notifications.isNotificationAllowed() ||
          await _notifications.requestPermissionToSendNotifications();
      if (!permissionGranted) return;

      await schedule(await getReminderTime());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize daily reminder notifications',
        error,
        stackTrace,
      );
    }
  }

  static Future<bool> isNotificationAllowed() {
    return _notifications.isNotificationAllowed();
  }

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  static Future<TimeOfDay> getReminderTime() async {
    final preferences = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: preferences.getInt(_hourKey) ?? 16,
      minute: preferences.getInt(_minuteKey) ?? 0,
    );
  }

  static Future<bool> schedule(TimeOfDay time) async {
    await _ensureInitialized();
    final permissionGranted =
        await _notifications.isNotificationAllowed() ||
        await _notifications.requestPermissionToSendNotifications();
    if (!permissionGranted) return false;

    await _notifications.cancelSchedule(_notificationId);
    final localTimeZone = await _notifications.getLocalTimeZoneIdentifier();
    final scheduled = await _notifications.createNotification(
      content: NotificationContent(
        id: _notificationId,
        channelKey: _channelKey,
        title: 'vehnWay',
        body:
            'Take a moment to use vehnWay and keep your driving insights up to date.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        timeZone: localTimeZone,
      ),
    );

    final isScheduled =
        scheduled ||
        (await _notifications.listScheduledNotifications()).any(
          (notification) => notification.content?.id == _notificationId,
        );
    if (!isScheduled) {
      AppLogger.error('Daily vehnWay reminder could not be scheduled');
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, true);
    await preferences.setInt(_hourKey, time.hour);
    await preferences.setInt(_minuteKey, time.minute);
    return true;
  }

  static Future<void> disable() async {
    await _ensureInitialized();
    await _notifications.cancelSchedule(_notificationId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, false);
  }

  static Future<void> _ensureInitialized() async {
    final initialized = await _notifications.initialize(null, [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Daily reminders',
        channelDescription: 'Reminders to use vehnWay each day.',
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      ),
    ]);

    if (!initialized) {
      throw StateError('Daily reminder notifications could not be initialized');
    }
  }
}
