import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;

  // Register user in Supabase
  Future<void> registerUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    try {
      await initialize();
    } catch (e) {
      rethrow;
    }
  }

  // Initialize Supabase
  Future<void> initialize() async {
    try {
      _client = Supabase.instance.client;
      
    } catch (e) {
      
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
        _client = Supabase.instance.client;
        
      } catch (e) {
        
        throw Exception('Failed to initialize Supabase: $e');
      }
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
      
      await initialize();

      // Build update map with only non-null values
      final Map<String, dynamic> updateData = {
        'name': fullName,
        'username': username,
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }

      // Update only the specified fields while maintaining the firebaseuid
      final response =
          await _client
              .from('userdetails')
              .update(updateData)
              .eq(
                'firebaseuid',
                userId,
              ) // Use firebaseuid to find the correct record
              .select();

      

      if ((response as List).isEmpty) {
        throw Exception('User record not found');
      }
    } catch (e) {
      
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    try {
      
      await initialize();

      final fileExt = file.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().toLocal().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage
          .from('user_avatars')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _client.storage
          .from('user_avatars')
          .getPublicUrl(filePath);

      
      return imageUrl;
    } catch (e) {
      
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserdetails(String firebaseUuid) async {
    try {
      if (firebaseUuid.isEmpty) {
        
        return null;
      }

      // Query Supabase using Firebase UID
      
      await initialize(); // Ensure client is initialized

      final response =
          await _client
              .from('userdetails')
              .select()
              .eq('firebaseuid', firebaseUuid)
              .maybeSingle();

      

      if (response == null) {
        
        return null;
      }

      return response;
    } catch (e) {
      
      
      
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVehicleDetails(int vehicleId) async {
    try {
      
      await initialize(); // Ensure client is initialized

      final vehicle =
          await _client
              .from('vehicledetails')
              .select()
              .eq('vehicleid', vehicleId)
              .maybeSingle();

      
      return vehicle;
    } catch (e) {
      
      
      
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVehiclesByUserId(
    String firebaseUuid,
  ) async {
    try {
      
      await initialize(); // Ensure client is initialized

      // Step 1: Get the vehicle details directly from vehicledetails table using firebaseuid
      final vehiclesResponse = await _client
          .from('vehicledetails')
          .select()
          .eq('firebaseuid', firebaseUuid);

      
      return List<Map<String, dynamic>>.from(vehiclesResponse);
    } catch (e) {
      
      
      
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
      
      await initialize(); // Ensure client is initialized
    } catch (e) {
      throw Exception('Failed to update vehicle details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDrives(int vehicleId) async {
    try {
      
      await initialize();

      // Query 'trips' table directly
      final response = await _client
          .from('trips')
          .select()
          .eq('vehicleid', vehicleId)
          .order('starttime', ascending: false);

      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      
      
      return [];
    }
  }
  /*
  Future<List<Map<String, dynamic>>> fetchDriveData({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      
      
      await initialize();

      // Call Supabase RPC function to bypass client-side row limits
      final response = await _client.rpc(
        'get_drive_data',
        params: {
          '_vehicle_id': vehicleId,
          '_start_time': startTime.toIso8601String(),
          '_end_time': endTime.toIso8601String(),
        },
      );

      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      
      
      return [];
    }
  }
*/

  Future<void> createSupabaseUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      
      await initialize();

      // Check if user exists
      final existingUser =
          await _client
              .from('userdetails')
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();

      if (existingUser != null) {
        
        return;
      }

      
      final name = displayName ?? 'New User';
      final username = name.split(' ')[0];

      await _client.from('userdetails').insert({
        'firebaseuid': uid,
        'email': email,
        'name': name,
        'username': username,
        'created_at': DateTime.now().toLocal().toIso8601String(),
        'role': 'User',
      });

      
    } catch (e) {
      
      
      // Don't rethrow, just log. The subsequent fetch will fail if this failed.
    }
  }

  Future<void> createVehicle({
    required String firebaseUid,
    required String model,
    required String registration,
    required String insurance,
    String? puc,
  }) async {
    try {
      
      await initialize(); // Ensure client is initialized
      
    } catch (e) {
      
      
      
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveEvents({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await initialize();

      final response = await _client
          .from('driving_events')
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
      await initialize();

      final response = await _client.rpc(
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
      
      await initialize(); // Ensure client is initialized

      // We explicitly select the deleted record to verify if it was actually deleted.
      // If RLS prevents it, this might return empty.
      final response =
          await _client
              .from('vehicledetails')
              .delete()
              .eq('vehicleid', vehicleId)
              .select();

      

      if ((response as List).isEmpty) {
        throw Exception(
          "Delete operation returned no rows. Possible RLS policy violation or record not found.",
        );
      }

      
    } catch (e) {
      
      
      
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  Future<void> deleteUser(String firebaseUid) async {
    try {
      
      await initialize();

      // Check if user exists first to distinguish between RLS block and already-deleted
      final checkUser =
          await _client
              .from('userdetails')
              .select()
              .eq('firebaseuid', firebaseUid)
              .maybeSingle();

      if (checkUser == null) {
        return;
      }

      final response =
          await _client
              .from('userdetails')
              .delete()
              .eq('firebaseuid', firebaseUid)
              .select();

      

      if ((response as List).isEmpty) {
        throw Exception(
          "Supabase RLS Error: Your Supabase database is blocking the user account deletion. Please go to your Supabase Dashboard -> Authentication -> Policies and ensure there is an active DELETE policy on the 'userdetails' table.",
        );
      } else {
        
      }
    } catch (e) {
      
      
      
      throw Exception('Failed to delete Supabase user: $e');
    }
  }
}
