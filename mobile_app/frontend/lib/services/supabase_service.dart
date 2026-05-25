import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';

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
          url: dotenv.get('SUPABASE_PROD_URL'),
          anonKey: dotenv.get('SUPABASE_PROD_ANON_KEY'),
          accessToken: _getFirebaseAccessToken,
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

  Future<String?> _getFirebaseAccessToken() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return firebaseUser.getIdToken();
  }

  /// Returns an authenticated Supabase client with the current Firebase user's JWT.
  /// This token is used by RLS policies to verify auth.uid() server-side.
  Future<SupabaseClient> _getAuthenticatedClient() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Not authenticated: Firebase user is null');
    }

    try {
      // Ensure Supabase client is initialized with the Firebase accessToken callback.
      final client = await _getOrInitClient();

      AppLogger.info(
        'Authenticated Supabase client created for user ${firebaseUser.uid}',
      );
      return client;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create authenticated Supabase client',
        e,
        stack,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Authenticated client creation failed',
      );
      rethrow;
    }
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
    required String fullName,
    required String username,
    String? phone,
    String? address,
    String? profilePictureUrl,
  }) async {
    try {
      final client = await _getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      final Map<String, dynamic> updateData = {
        'name': fullName,
        'username': username,
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }

      // Filter by firebaseuid so users only update their own record
      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .update(updateData)
              .eq('firebaseuid', firebaseUser.uid)
              .select();

      if ((response as List).isEmpty) {
        throw Exception('User record not found or RLS policy blocked update');
      }
      AppLogger.info('User profile updated successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to update profile', e, stack);
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

  Future<Map<String, dynamic>?> getUserdetails() async {
    try {
      final client = await _getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      // Filter by the signed-in Firebase UID so the query stays single-row safe.
      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', firebaseUser.uid)
              .maybeSingle();

      return response;
    } catch (e, stack) {
      AppLogger.warning('Error fetching user details', e, stack);
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

  Future<List<Map<String, dynamic>>> getVehiclesByUserId() async {
    try {
      final client = await _getAuthenticatedClient();

      // RLS policy ensures users can only see their own vehicles
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
    required String insurance,
    required String registration,
    required String? puc,
    required String model,
  }) async {
    try {
      final client = await _getAuthenticatedClient();
      // RLS policy ensures users can only update their own vehicles
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
      final client = await _getAuthenticatedClient();

      final response = await client
          .from(AppConfig.tableSessions)
          .select()
          .eq('vehicle_id', vehicleId)
          .order('start_time', ascending: false);

      final List<Map<String, dynamic>> allDrives =
          List<Map<String, dynamic>>.from(response);

      // RLS policy ensures users can only see trips for their own vehicles
      // Filter drives that are greater than 1 minute
      /*
      final filteredDrives =
          allDrives.where((drive) {
            if (drive['start_time'] == null || drive['end_time'] == null) {
              return false;
            }
            final start = DateTime.tryParse(drive['start_time']);
            final end = DateTime.tryParse(drive['end_time']);
            if (start == null || end == null) return false;

            return end.difference(start).inMinutes > 1;
          }).toList();
      */

      return allDrives;
    } catch (e, stack) {
      AppLogger.error('Error fetching drives for vehicle $vehicleId', e, stack);
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchLatestDrive(int vehicleId) async {
    try {
      final client = await _getAuthenticatedClient();

      final response = await client
          .from(AppConfig.tableSessions)
          .select()
          .eq('vehicle_id', vehicleId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e, stack) {
      AppLogger.error('Error fetching latest drive for vehicle $vehicleId', e, stack);
      return null;
    }
  }

  /// Fetches the last known GPS location coordinates for a specific vehicle by checking
  /// its latest session and querying the most recent gps_data log.
  Future<Map<String, double>?> getLastKnownLocation(int vehicleId) async {
    try {
      final client = await _getAuthenticatedClient();
      
      // 1. Fetch the latest session for the given vehicleId
      final latestSession = await client
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
      final latestGps = await client
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

      return {
        'latitude': lat,
        'longitude': lng,
      };
    } catch (e, stack) {
      AppLogger.warning('Error fetching last known location for vehicle $vehicleId', e, stack);
      return null;
    }
  }

  /// Retrieves user details, or creates a new record if it doesn't exist.
  /// This encapsulates the logic previously held in the UserProvider.
  /// The authenticated Firebase token ensures the user can only access their own record.
  Future<Map<String, dynamic>?> getOrCreateUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final client = await _getAuthenticatedClient();

      // Filter by uid to avoid fetching every row when multiple profiles exist.
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

      // Get the current Firebase user to ensure we set the correct firebaseuid
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during user creation');
      }

      final newData = {
        'firebaseuid': firebaseUser.uid,
        'email': email,
        'name': name,
        'username': username,
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
      // Handle race condition where another parallel call already created the record
      if (e is PostgrestException && e.code == '23505') {
        AppLogger.info('Conflict (23505) in getOrCreateUser for $uid. Retrying select...');
        try {
          final client = await _getAuthenticatedClient();
          final existingUser = await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();
          if (existingUser != null) {
            return existingUser;
          }
        } catch (retryError, retryStack) {
          AppLogger.error('Failed to refetch user after conflict', retryError, retryStack);
        }
      }

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
    required String model,
    required String registration,
    required String insurance,
    String? puc,
  }) async {
    try {
      final client = await _getAuthenticatedClient();

      // Get the current Firebase user to ensure we set the correct firebaseuid
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during vehicle creation');
      }

      // Set firebaseuid explicitly from the authenticated user
      // This prevents users from creating vehicles for other users
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

  Future<List<Map<String, dynamic>>> fetchDriveEvents({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final client = await _getAuthenticatedClient();

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
      final client = await _getAuthenticatedClient();

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
      final client = await _getAuthenticatedClient();

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

  Future<void> deleteUser() async {
    try {
      final client = await _getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      // Check if the current user's row exists first.
      final checkUser =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', firebaseUser.uid)
              .maybeSingle();

      if (checkUser == null) {
        return;
      }

      // RLS policy ensures users can only delete their own record
      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .delete()
              .eq('firebaseuid', firebaseUser.uid)
              .select();

      if ((response as List).isEmpty) {
        throw Exception(
          "Supabase RLS Error: Your Supabase database is blocking account deletion. Check your DELETE policy on 'userdetails'.",
        );
      }
      AppLogger.info('User deleted successfully from Supabase');
    } catch (e, stack) {
      AppLogger.error('Failed to delete Supabase user', e, stack);
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
      final client = await _getAuthenticatedClient();
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
