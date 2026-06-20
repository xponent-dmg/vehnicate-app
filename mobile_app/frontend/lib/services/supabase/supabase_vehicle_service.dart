import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';

import 'supabase_core_service.dart';

class SupabaseVehicleService {
  static final SupabaseVehicleService _instance =
      SupabaseVehicleService._internal();
  factory SupabaseVehicleService() => _instance;
  SupabaseVehicleService._internal();

  final _core = SupabaseCoreService();

  Future<Map<String, dynamic>?> getVehicleDetails(int vehicleId) async {
    try {
      final client = await _core.getOrInitClient();

      final vehicle =
          await client
              .from(AppConfig.tableVehicleDetails)
              .select()
              .eq('vehicleid', vehicleId)
              .maybeSingle();

      return vehicle;
    } catch (e, stack) {
      AppLogger.warning(
        'Error fetching vehicle details for $vehicleId',
        e,
        stack,
      );
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVehiclesByUserId() async {
    try {
      final client = await _core.getAuthenticatedClient();

      final vehiclesResponse =
          await client.from(AppConfig.tableVehicleDetails).select();

      return List<Map<String, dynamic>>.from(vehiclesResponse);
    } catch (e, stack) {
      AppLogger.error('Error fetching vehicles', e, stack);
      return [];
    }
  }

  Future<void> updateVehicleDetails({
    required int vehicleId,
    required String? insurance,
    required String registration,
    required String? puc,
    required String model,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();

      await client
          .from(AppConfig.tableVehicleDetails)
          .update({
            'insurance': insurance,
            'registration': registration,
            'puc': puc,
            'model': model,
          })
          .eq('vehicleid', vehicleId);
      AppLogger.info('Vehicle details updated for $vehicleId');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to update vehicle details for $vehicleId',
        e,
        stack,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Vehicle details update failed',
      );
      throw Exception('Failed to update vehicle details: $e');
    }
  }

  Future<void> createVehicle({
    required String model,
    required String registration,
    String? insurance,
    String? puc,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during vehicle creation');
      }

      await client.from(AppConfig.tableVehicleDetails).insert({
        'firebaseuid': firebaseUser.uid,
        'model': model,
        'registration': registration,
        'insurance': insurance,
        'puc': puc,
        'created_at': DateTime.now().toLocal().toIso8601String(),
      });
      AppLogger.info('New vehicle created');
    } catch (e, stack) {
      AppLogger.error('Failed to create vehicle', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Vehicle creation failed',
      );
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final response =
          await client
              .from(AppConfig.tableVehicleDetails)
              .delete()
              .eq('vehicleid', vehicleId)
              .select();

      if ((response as List).isEmpty) {
        throw Exception(
          "Delete operation returned no rows. Possible RLS policy violation or record not found.",
        );
      }
      AppLogger.info('Vehicle $vehicleId deleted successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to delete vehicle $vehicleId', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Vehicle deletion failed',
      );
      throw Exception('Failed to delete vehicle: $e');
    }
  }
}
