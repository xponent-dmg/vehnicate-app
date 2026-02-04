import 'dart:async';
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
      print('Ensuring Supabase client is initialized...');
      await initialize();

      // Sanitize email
      final sanitizedEmail = email.trim().toLowerCase();

      try {
        // First create the user record in userdetails table
        print('Attempting to create user record in userdetails...');
        print('Firebase UID: $uid');
        print('Email: $sanitizedEmail');

        final response =
            await _client.from('userdetails').insert({
              'firebaseuid': uid,
              'email': sanitizedEmail,
              'name': 'New User', // Required field, can be updated later
              'created_at': DateTime.now().toIso8601String(),
              'role': 'User', // Notice the capital 'U' as per your enum check
            }).select();

        print('User record created in userdetails: ${response.toString()}');

        print('Attempting Supabase auth signup...');
        // Then sign up the user in Supabase auth
        try {
          final authResponse = await _client.auth.signUp(
            email: sanitizedEmail,
            password: password,
            data: {'firebaseuid': uid},
          );

          print('Supabase auth response: ${authResponse.toString()}');

          if (authResponse.user?.id != null) {
            print(
              'Updating user record with Supabase ID: ${authResponse.user!.id}',
            );
            try {
              final updateResponse =
                  await _client
                      .from('userdetails')
                      .update({'supabase_uid': authResponse.user!.id})
                      .eq('firebaseuid', uid)
                      .select();
              print('Update response: ${updateResponse.toString()}');
            } catch (e) {
              print('Warning: Could not update supabase_uid: $e');
              // Don't rethrow this error since it's not critical
            }
          }
        } catch (e) {
          print('Warning: Supabase auth signup failed: $e');
          // Don't rethrow this error since the user record is already created
          // This allows the registration to succeed even if auth fails
        }
      } catch (e) {
        print('Error in user registration process: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      print('Error in Supabase service:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Initialize Supabase
  Future<void> initialize() async {
    try {
      _client = Supabase.instance.client;
      print('Using existing Supabase instance');
    } catch (e) {
      print('No existing Supabase instance found');
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
        _client = Supabase.instance.client;
        print('New Supabase instance initialized successfully');
      } catch (e) {
        print('Error initializing Supabase: $e');
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
  }) async {
    try {
      print('Updating profile for user with Firebase UID: $userId');

      // Build update map with only non-null values
      final Map<String, dynamic> updateData = {
        'name': fullName,
        'username': username,
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;

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

      print('Profile update response: $response');

      if ((response as List).isEmpty) {
        throw Exception('User record not found');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserdetails(String firebaseUuid) async {
    try {
      if (firebaseUuid.isEmpty) {
        print("Error: Firebase UID is empty");
        return null;
      }

      // Query Supabase using Firebase UID
      print("Fetching user details for Firebase UID: $firebaseUuid");
      await initialize(); // Ensure client is initialized

      final response =
          await _client
              .from('userdetails')
              .select()
              .eq('firebaseuid', firebaseUuid)
              .maybeSingle();

      print("Supabase user details response: $response");

      if (response == null) {
        print("No user found in Supabase for Firebase UID: $firebaseUuid");
        return null;
      }

      return response;
    } catch (e, stackTrace) {
      print("Error getting user details from Supabase:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVehicleDetails(int vehicleId) async {
    try {
      print("Fetching vehicle details for ID: $vehicleId");
      await initialize(); // Ensure client is initialized

      final vehicle =
          await _client
              .from('vehicledetails')
              .select()
              .eq('vehicleid', vehicleId)
              .maybeSingle();

      print("Vehicle details response: $vehicle");
      return vehicle;
    } catch (e, stackTrace) {
      print("Error getting vehicle details:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVehiclesByUserId(
    String firebaseUuid,
  ) async {
    try {
      print("Fetching vehicles for user with Firebase UID: $firebaseUuid");
      await initialize(); // Ensure client is initialized

      // Step 1: Get the vehicle details directly from vehicledetails table using firebaseuid
      final vehiclesResponse = await _client
          .from('vehicledetails')
          .select()
          .eq('firebaseuid', firebaseUuid);

      print("Vehicles details response: $vehiclesResponse");
      return List<Map<String, dynamic>>.from(vehiclesResponse);
    } catch (e, stackTrace) {
      print("Error getting vehicles by user id:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
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
      print("Updating vehicle details for ID: $vehicleId");
      await initialize(); // Ensure client is initialized

      final response =
          await _client
              .from('vehicledetails')
              .update({
                'insurance': insurance,
                'registration': registration,
                'puc': puc,
                'model': model,
              })
              .eq('vehicleid', vehicleId)
              .select();

      print("Vehicle details update response: $response");
    } catch (e, stackTrace) {
      print("Error updating vehicle details:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      throw Exception('Failed to update vehicle details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDrives(int vehicleId) async {
    try {
      print('Fetching drives for vehicle ID: $vehicleId');
      await initialize();

      // Query 'trips' table directly
      final response = await _client
          .from('trips')
          .select()
          .eq('vehicleid', vehicleId)
          .order('starttime', ascending: false);

      print('Drives fetched: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('Error fetching drives: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveData({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      print('Fetching drive data for vehicle $vehicleId');
      print('Data Time Range: ${startTime.toLocal()} to ${endTime.toLocal()}');
      await initialize();

      // Query 'datatransmission' table for sensor data within the time range
      final response = await _client
          .from('datatransmission')
          .select()
          .eq('vehicleid', vehicleId)
          .gte('timesent', startTime.toIso8601String())
          .lte('timesent', endTime.toIso8601String())
          .order('timesent', ascending: true)
          .limit(50000);

      print('Drive data points fetched: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('Error fetching drive data: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> createSupabaseUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      print('Ensuring Supabase client is initialized...');
      await initialize();

      // Check if user exists
      final existingUser =
          await _client
              .from('userdetails')
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();

      if (existingUser != null) {
        print('User already exists in Supabase: $uid');
        return;
      }

      print('Creating new user in Supabase for UID: $uid');
      final name = displayName ?? 'New User';
      final username = name.split(' ')[0];

      await _client.from('userdetails').insert({
        'firebaseuid': uid,
        'email': email,
        'name': name,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
        'role': 'User',
      });

      print('Successfully created user in Supabase');
    } catch (e, stackTrace) {
      print('Error creating Supabase user: $e');
      print('Stack trace: $stackTrace');
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
      print('Creating vehicle for user with Firebase UID: $firebaseUid');
      await initialize(); // Ensure client is initialized

      final response =
          await _client.from('vehicledetails').insert({
            'firebaseuid': firebaseUid,
            'model': model,
            'registration': registration,
            'insurance': insurance,
            'puc': puc,
            'created_at': DateTime.now().toLocal().toIso8601String(),
          }).select();

      print('Vehicle creation response: $response');
    } catch (e, stackTrace) {
      print('Error creating vehicle:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveEvents({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      print('Fetching drive events for vehicle $vehicleId');
      print(
        'Events Time Range: ${startTime.toLocal()} to ${endTime.toLocal()}',
      );
      await initialize();

      final response = await _client
          .from('driving_events')
          .select()
          .eq('vehicle_id', vehicleId)
          .gte('timestamp', startTime.toIso8601String())
          .lte('timestamp', endTime.toIso8601String())
          .order('timestamp', ascending: true);

      print('Events fetched: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('Error fetching drive events: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriveRoute({
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      print('Fetching drive route for vehicle $vehicleId');
      print(
        'Route Time Range (d/m/y): ${startTime.toLocal()} to ${endTime.toLocal()}',
      );
      await initialize();

      final response = await _client.rpc(
        'get_clean_route',
        params: {
          'vehicle_id_input': vehicleId,
          'start_time_input': startTime.toIso8601String(),
          'end_time_input': endTime.toIso8601String(),
        },
      );

      print('Route points fetched (unique/cleaned): ${response.length}');
      // RPC returns a list directly typically, but we cast for safety
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('Error fetching drive route: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
