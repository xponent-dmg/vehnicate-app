import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opsin/core/constants/app_config.dart';
import 'package:opsin/utils/app_logger.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  /// Ensures the client is initialized. This should be called once in main.dart.
  static Future<void> init() async {
    await _instance._getOrInitClient();
  }

  Future<SupabaseClient> _getOrInitClient() async {
    if (_client != null) return _client!;

    try {
      _client = Supabase.instance.client;
      return _client!;
    } catch (_) {
      try {
        await Supabase.initialize(
          url: dotenv.get('SUPABASE_URL'),
          anonKey: dotenv.get('SUPABASE_ANON_KEY'),
        );
        _client = Supabase.instance.client;
        return _client!;
      } catch (err, stack) {
        AppLogger.error(
          'Critical: Failed to initialize Supabase client',
          err,
          stack,
        );
        FirebaseCrashlytics.instance.recordError(
          err,
          stack,
          reason: 'Supabase Initialization Failed',
        );
        throw Exception('Failed to initialize Supabase: $err');
      }
    }
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService.init() in main.dart',
      );
    }
    return _client!;
  }

  // Register user in Supabase
  Future<void> registerUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    try {
      await _getOrInitClient();
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String username,
    String? phone,
    String? address,
    String? profilePictureUrl,
  }) async {
    try {
      final client = await _getOrInitClient();

      final Map<String, dynamic> updateData = {
        'name': fullName,
        'username': username,
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .update(updateData)
              .eq('firebaseuid', userId)
              .select();

      if ((response as List).isEmpty) {
        throw Exception('User record not found');
      }
      AppLogger.info('User profile updated successfully for $userId');
    } catch (e, stack) {
      AppLogger.error('Failed to update profile for $userId', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'User profile update failed',
      );
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    try {
      final client = await _getOrInitClient();

      final fileExt = file.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().toLocal().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await client.storage
          .from(AppConfig.bucketUserAvatars)
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = client.storage
          .from(AppConfig.bucketUserAvatars)
          .getPublicUrl(filePath);

      AppLogger.info('Profile picture uploaded successfully for $userId');
      return imageUrl;
    } catch (e, stack) {
      AppLogger.error('Failed to upload profile picture for $userId', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Profile picture upload failed',
      );
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserdetails(String firebaseUuid) async {
    try {
      if (firebaseUuid.isEmpty) return null;

      final client = await _getOrInitClient();

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', firebaseUuid)
              .maybeSingle();

      return response;
    } catch (e, stack) {
      AppLogger.warning(
        'Error fetching user details for $firebaseUuid',
        e,
        stack,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVehicleDetails(int vehicleId) async {
    try {
      final client = await _getOrInitClient();

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

  Future<List<Map<String, dynamic>>> getVehiclesByUserId(
    String firebaseUuid,
  ) async {
    try {
      final client = await _getOrInitClient();

      final vehiclesResponse = await client
          .from(AppConfig.tableVehicleDetails)
          .select()
          .eq('firebaseuid', firebaseUuid);

      return List<Map<String, dynamic>>.from(vehiclesResponse);
    } catch (e, stack) {
      AppLogger.error(
        'Error fetching vehicles for user $firebaseUuid',
        e,
        stack,
      );
      return [];
    }
  }

  Future<void> updateVehicleDetails({
    required int vehicleId,
    required String insurance,
    required String registration,
    required String? puc,
    required String model,
  }) async {
    try {
      final client = await _getOrInitClient();
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

  Future<List<Map<String, dynamic>>> fetchDrives(int vehicleId) async {
    try {
      final client = await _getOrInitClient();

      final response = await client
          .from(AppConfig.tableTrips)
          .select()
          .eq('vehicleid', vehicleId)
          .order('starttime', ascending: false);

      final List<Map<String, dynamic>> allDrives =
          List<Map<String, dynamic>>.from(response);

      // Filter drives that are greater than 1 minute
      final filteredDrives =
          allDrives.where((drive) {
            if (drive['starttime'] == null || drive['endtime'] == null) {
              return false;
            }
            final start = DateTime.tryParse(drive['starttime']);
            final end = DateTime.tryParse(drive['endtime']);
            if (start == null || end == null) return false;

            return end.difference(start).inMinutes > 1;
          }).toList();

      return filteredDrives;
    } catch (e, stack) {
      AppLogger.error('Error fetching drives for vehicle $vehicleId', e, stack);
      return [];
    }
  }

  /// Retrieves user details, or creates a new record if it doesn't exist.
  /// This encapsulates the logic previously held in the UserProvider.
  Future<Map<String, dynamic>?> getOrCreateUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final client = await _getOrInitClient();

      final existingUser =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();

      if (existingUser != null) {
        return existingUser;
      }

      final name = displayName ?? 'New User';
      final username = name.split(' ')[0];

      final newData = {
        'firebaseuid': uid,
        'email': email,
        'name': name,
        'username': username,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'role': 'User',
      };

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .insert(newData)
              .select()
              .single();

      AppLogger.info('New user record created in Supabase for $uid');
      return response;
    } catch (e, stack) {
      AppLogger.error('Error in getOrCreateUser for $uid', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'getOrCreateUser failed',
      );
      return null;
    }
  }

  // Keeping ensureUserExists for backward compatibility if needed,
  // but redirected to getOrCreateUser or simplified.
  Future<void> ensureUserExists({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    await getOrCreateUser(uid: uid, email: email, displayName: displayName);
  }

  Future<void> createVehicle({
    required String firebaseUid,
    required String model,
    required String registration,
    required String insurance,
    String? puc,
  }) async {
    try {
      final client = await _getOrInitClient();
      await client.from(AppConfig.tableVehicleDetails).insert({
        'firebaseuid': firebaseUid,
        'model': model,
        'registration': registration,
        'insurance': insurance,
        'puc': puc,
        'created_at':
            DateTime.now().toUtc().toIso8601String(), // Corrected to UTC
      });
      AppLogger.info('New vehicle created for user $firebaseUid');
    } catch (e, stack) {
      AppLogger.error('Failed to create vehicle for $firebaseUid', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Vehicle creation failed',
      );
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveEvents({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final client = await _getOrInitClient();

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
      final client = await _getOrInitClient();

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

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      final client = await _getOrInitClient();

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

  Future<void> deleteUser(String firebaseUid) async {
    try {
      final client = await _getOrInitClient();

      // Check if user exists first to distinguish between RLS block and already-deleted
      final checkUser =
          await client
              .from('userdetails')
              .select()
              .eq('firebaseuid', firebaseUid)
              .maybeSingle();

      if (checkUser == null) {
        return;
      }

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .delete()
              .eq('firebaseuid', firebaseUid)
              .select();

      if ((response as List).isEmpty) {
        throw Exception(
          "Supabase RLS Error: Your Supabase database is blocking account deletion. Check your DELETE policy on 'userdetails'.",
        );
      }
      AppLogger.info('User $firebaseUid deleted successfully from Supabase');
    } catch (e, stack) {
      AppLogger.error('Failed to delete Supabase user $firebaseUid', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Account deletion failed',
      );
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final client = await _getOrInitClient();
      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .select('username')
              .eq('username', username)
              .maybeSingle();
      return response == null;
    } catch (e, stack) {
      AppLogger.warning(
        'Error checking username availability for $username',
        e,
        stack,
      );
      throw Exception('Failed to check username availability: $e');
    }
  }
}
