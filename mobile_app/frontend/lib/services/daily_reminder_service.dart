import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vehnway/utils/app_logger.dart';

class DailyReminderService {
  static const _notificationId = 1600;
  static const _channelKey = 'vehnway_daily_reminder';
  static const _reminderHour = 16;
  static const _reminderMinute = 0;

  static Future<void> initialize() async {
    final notifications = AwesomeNotifications();

    try {
      final initialized = await notifications.initialize(null, [
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
        AppLogger.error(
          'Daily reminder notifications could not be initialized',
        );
        return;
      }

      final permissionGranted =
          await notifications.isNotificationAllowed() ||
          await notifications.requestPermissionToSendNotifications();

      if (!permissionGranted) {
        AppLogger.warning(
          'Daily reminder notifications are not permitted by the user',
        );
        return;
      }

      final scheduled = await notifications.createNotification(
        content: NotificationContent(
          id: _notificationId,
          channelKey: _channelKey,
          title: 'Time for vehnWay',
          body:
              'Take a moment to use vehnWay and keep your driving insights up to date.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: _reminderHour,
          minute: _reminderMinute,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
        ),
      );

      if (!scheduled) {
        AppLogger.error('Daily vehnWay reminder could not be scheduled');
        return;
      }

      AppLogger.info(
        'Daily vehnWay reminder scheduled for '
        '${_reminderHour.toString().padLeft(2, '0')}:'
        '${_reminderMinute.toString().padLeft(2, '0')}',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize daily reminder notifications',
        error,
        stackTrace,
      );
    }
  }
}
