import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;

  // Register user in Supabase
  Future<void> registerUser({required String uid, required String email, required String password}) async {
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
            print('Updating user record with Supabase ID: ${authResponse.user!.id}');
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
  Future<void> updateUserProfile({required String userId, required String fullName, required String username}) async {
    try {
      print('Updating profile for user with Firebase UID: $userId');

      // Update only the specified fields while maintaining the firebaseuid
      final response =
          await _client
              .from('userdetails')
              .update({'name': fullName, 'username': username})
              .eq('firebaseuid', userId) // Use firebaseuid to find the correct record
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

      final response = await _client.from('userdetails').select().eq('firebaseuid', firebaseUuid).maybeSingle();

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

      final vehicle = await _client.from('vehicledetails').select().eq('vehicleid', vehicleId).maybeSingle();

      print("Vehicle details response: $vehicle");
      return vehicle;
    } catch (e, stackTrace) {
      print("Error getting vehicle details:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVehicleByUserId(String firebaseUuid) async {
    try {
      print("Fetching vehicle for user with Firebase UID: $firebaseUuid");
      await initialize(); // Ensure client is initialized

      // Step 1: Get the vehicle_id from the userdetails table
      final userResponse =
          await _client.from('userdetails').select('vehicleid').eq('firebaseuid', firebaseUuid).maybeSingle();

      print("User-vehicle response: $userResponse");

      if (userResponse == null) {
        print("No vehicle ID found for user: $firebaseUuid");
        return null;
      }

      final vehicleId = userResponse['vehicleid'];
      if (vehicleId == null) {
        print("Vehicle ID is null for user: $firebaseUuid");
        return null;
      }

      // Step 2: Get vehicle details from vehicledetails table
      final vehicleResponse = await getVehicleDetails(vehicleId);
      return vehicleResponse;
    } catch (e, stackTrace) {
      print("Error getting vehicle by user id:");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      return null;
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
              .update({'insurance': insurance, 'registration': registration, 'puc': puc, 'model': model})
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
}
