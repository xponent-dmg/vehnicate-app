import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Owns the Android foreground notification for an IMU-only drive.
///
/// Sensor acquisition stays in [ImuCollectionController]; this task exists so
/// Android keeps the active drive visible to the user while the app is not on
/// the collector page.
class ForegroundCollectionService {
  static const _serviceId = 1201;
  static const stopActionId = 'stop_imu_collection';

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
      notificationTitle: 'VehnWay is collecting drive data',
      notificationText: 'IMU and location collection is active.',
      notificationButtons: const [
        NotificationButton(id: stopActionId, text: 'Stop'),
      ],
      callback: startImuForegroundTask,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
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
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}
