import 'package:hive_flutter/hive_flutter.dart';
import 'package:opsin/utils/app_logger.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String boxMetadata = 'metadata';
  static const String boxUserData = 'user_data';
  static const String boxVehicleData = 'vehicle_data';
  static const String boxTripData = 'trip_data';

  Future<void> init() async {
    try {
      await Hive.openBox(boxMetadata);
      await Hive.openBox(boxUserData);
      await Hive.openBox(boxVehicleData);
      await Hive.openBox(boxTripData);
      AppLogger.info('Cache Boxes opened successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to open Cache Boxes', e, stack);
    }
  }

  // --- User Caching ---
  Future<void> setUserDetail(String uid, Map<String, dynamic> data) async {
    final box = Hive.box(boxUserData);
    await box.put(uid, data);
  }

  Map<String, dynamic>? getUserDetail(String uid) {
    final box = Hive.box(boxUserData);
    final data = box.get(uid);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // --- Vehicle Caching ---
  Future<void> setVehicles(
    String uid,
    List<Map<String, dynamic>> vehicles,
  ) async {
    final box = Hive.box(boxVehicleData);
    await box.put(uid, vehicles);
  }

  List<Map<String, dynamic>> getVehicles(String uid) {
    final box = Hive.box(boxVehicleData);
    final data = box.get(uid);
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // --- Trip Caching ---
  Future<void> setTrips(int vehicleId, List<Map<String, dynamic>> trips) async {
    final box = Hive.box(boxTripData);
    await box.put(vehicleId.toString(), trips);
  }

  List<Map<String, dynamic>> getTrips(int vehicleId) {
    final box = Hive.box(boxTripData);
    final data = box.get(vehicleId.toString());
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // --- General cleanup ---
  Future<void> clearAuthCache() async {
    await Hive.box(boxUserData).clear();
    await Hive.box(boxVehicleData).clear();
    await Hive.box(boxTripData).clear();
    AppLogger.info('Cache cleared on logout');
  }
}
