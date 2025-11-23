import 'package:permission_handler/permission_handler.dart';

/// Service for handling location permissions and checking location service status
class LocationPermissionService {
  /// Requests location permission from the user
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Checks if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Checks if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Opens app settings for the user to manually enable permissions
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Checks both permission and service status
  Future<LocationStatus> checkLocationStatus() async {
    final permissionGranted = await isLocationPermissionGranted();
    final serviceEnabled = await isLocationServiceEnabled();

    return LocationStatus(permissionGranted: permissionGranted, serviceEnabled: serviceEnabled);
  }

  /// Requests both permission and prompts to enable service if needed
  Future<LocationStatus> requestLocationAccess() async {
    // First check if services are enabled
    final serviceEnabled = await isLocationServiceEnabled();

    if (!serviceEnabled) {
      return LocationStatus(permissionGranted: false, serviceEnabled: false);
    }

    // Request permission
    final permissionGranted = await requestLocationPermission();

    return LocationStatus(permissionGranted: permissionGranted, serviceEnabled: serviceEnabled);
  }
}

/// Status class for location permission and service
class LocationStatus {
  final bool permissionGranted;
  final bool serviceEnabled;

  LocationStatus({required this.permissionGranted, required this.serviceEnabled});

  bool get isFullyEnabled => permissionGranted && serviceEnabled;
}
