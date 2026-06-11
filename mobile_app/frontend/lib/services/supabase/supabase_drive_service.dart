import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';

import 'supabase_core_service.dart';

class SupabaseDriveService {
  static final SupabaseDriveService _instance =
      SupabaseDriveService._internal();
  factory SupabaseDriveService() => _instance;
  SupabaseDriveService._internal();

  final _core = SupabaseCoreService();

  Future<List<Map<String, dynamic>>> fetchDrives(int vehicleId) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final response = await client
          .from(AppConfig.tableSessions)
          .select()
          .eq('vehicle_id', vehicleId)
          .order('start_time', ascending: false);

      final List<Map<String, dynamic>> allDrives =
          List<Map<String, dynamic>>.from(response);

      return allDrives;
    } catch (e, stack) {
      AppLogger.error('Error fetching drives for vehicle $vehicleId', e, stack);
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchLatestDrive(int vehicleId) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final response =
          await client
              .from(AppConfig.tableSessions)
              .select()
              .eq('vehicle_id', vehicleId)
              .order('start_time', ascending: false)
              .limit(1)
              .maybeSingle();

      return response;
    } catch (e, stack) {
      AppLogger.error(
        'Error fetching latest drive for vehicle $vehicleId',
        e,
        stack,
      );
      return null;
    }
  }

  /// Fetches the last known GPS location coordinates for a specific vehicle by checking
  /// its latest session and querying the most recent gps_data log.
  Future<Map<String, double>?> getLastKnownLocation(int vehicleId) async {
    try {
      final client = await _core.getAuthenticatedClient();

      // 1. Fetch the latest session for the given vehicleId
      final latestSession =
          await client
              .from(AppConfig.tableSessions)
              .select('session_id')
              .eq('vehicle_id', vehicleId)
              .order('start_time', ascending: false)
              .limit(1)
              .maybeSingle();

      if (latestSession == null) return null;
      final String? sessionId = latestSession['session_id'] as String?;
      if (sessionId == null) return null;

      // 2. Fetch the latest GPS coordinate recorded in this session from the gps_data table
      final latestGps =
          await client
              .from(AppConfig.tableGpsData)
              .select('latitude, longitude')
              .eq('session_id', sessionId)
              .order('timestamp_ms', ascending: false)
              .limit(1)
              .maybeSingle();

      if (latestGps == null) return null;

      final double? lat = (latestGps['latitude'] as num?)?.toDouble();
      final double? lng = (latestGps['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return null;

      return {'latitude': lat, 'longitude': lng};
    } catch (e, stack) {
      AppLogger.warning(
        'Error fetching last known location for vehicle $vehicleId',
        e,
        stack,
      );
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveEvents({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final response = await client
          .from(AppConfig.tableDrivingEvents)
          .select()
          .eq('vehicle_id', vehicleId)
          .gte('timestamp', startTime.toIso8601String())
          .lte('timestamp', endTime.toIso8601String())
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveRoute({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final response = await client.rpc(
        'get_clean_route',
        params: {
          'vehicle_id_input': vehicleId,
          'start_time_input': startTime.toIso8601String(),
          'end_time_input': endTime.toIso8601String(),
        },
      );

      // RPC returns a list directly typically, but we cast for safety
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
