import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _deviceIdKey = 'vehnway_unique_device_id';

  Future<String> getPersistentDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId != null) {
      return deviceId;
    }

    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Unique ID on iOS
      }
    } catch (e) {
      // Fallback to UUID if platform specific ID fails
    }

    if (deviceId == null || deviceId.isEmpty || deviceId == 'unknown') {
      deviceId = const Uuid().v4();
    }

    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }
}
