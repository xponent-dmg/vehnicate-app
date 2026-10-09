import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Owns the Android foreground notification for an IMU-only drive.
///
/// Sensor acquisition stays in [ImuCollectionController]; this task exists so
/// Android keeps the active drive visible to the user while the app is not on
/// the collector page.
class ForegroundCollectionService {
  static const _serviceId = 1201;
  static const stopActionId = 'stop_imu_collection';
  static const restoreActionId = 'restore_imu_notification';
  static const _notificationTitle = 'VehnWay is collecting drive data';
  static const _notificationText = 'IMU and location collection is active.';
  static const _notificationButtons = [
    NotificationButton(id: stopActionId, text: 'Stop'),
  ];

  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vehnway_imu_collection',
        channelName: 'VehnWay data collection',
        channelDescription: 'Shown while an IMU-only drive is being collected.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> ensureNotificationPermission() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.granted) return true;

    return await FlutterForegroundTask.requestNotificationPermission() ==
        NotificationPermission.granted;
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) return true;

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [
        ForegroundServiceTypes.location,
        ForegroundServiceTypes.dataSync,
      ],
      notificationTitle: _notificationTitle,
      notificationText: _notificationText,
      notificationButtons: _notificationButtons,
      callback: startImuForegroundTask,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Android normally prevents dismissal for ongoing notifications. This is a
  /// fallback for device-specific notification UIs that still allow a swipe.
  static Future<void> restoreNotification() async {
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: _notificationTitle,
      notificationText: _notificationText,
      notificationButtons: _notificationButtons,
    );
  }
}

@pragma('vm:entry-point')
void startImuForegroundTask() {
  FlutterForegroundTask.setTaskHandler(_ImuForegroundTaskHandler());
}

class _ImuForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isBackground) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == ForegroundCollectionService.stopActionId) {
      FlutterForegroundTask.sendDataToMain(
        ForegroundCollectionService.stopActionId,
      );
    }
  }

  @override
  void onNotificationDismissed() {
    // The main isolate owns the service API configuration. Ask it to rebuild
    // the ongoing notification as well as attempting the local restoration.
    FlutterForegroundTask.sendDataToMain(
      ForegroundCollectionService.restoreActionId,
    );
    unawaited(ForegroundCollectionService.restoreNotification());
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}
