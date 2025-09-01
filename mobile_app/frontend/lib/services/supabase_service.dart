import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SupabaseService {
  // Register user in Supabase 
  Future<void> registerUser({required String uid, required String email, required String password}) async {
    try {
      print('Ensuring Supabase client is initialized...');
      await initialize();
      
      // First, sign in to Supabase using email
      print('Signing in to Supabase...');
      try {
        await _client.auth.signInWithPassword(
          email: email,
          password: password 
        );
      } catch (e) {
        // If sign in fails, try signing up
        print('Sign in failed, attempting to sign up...');
        await _client.auth.signUp(
          email: email,
          password: password
        );
      }
      
      print('Checking Supabase connection...');
      try {
        final healthCheck = await _client.from('userdetails').select().limit(1);
        print('Supabase connection successful. Health check response: $healthCheck');
      } catch (e) {
        print('Supabase health check failed: $e');
      }
      
      print('Attempting to register user in Supabase...');
      print('User ID: $uid');
      print('Email: $email');
      
      // Get the current Supabase user's UUID
      final supabaseUid = _client.auth.currentUser?.id;
      
      final response = await _client.from('userdetails').insert({
        'firebasesuid': uid,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': supabaseUid,
        'role': 'user'  // Default role for new users
      }).select();
      
      print('Supabase response: $response');
      print('User registered successfully in Supabase');
    } catch (e, stackTrace) {
      print('Error registering user in Supabase:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow; // This will propagate the error to the signup page
    }
  }
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  
  bool _isStreaming = false;
  String? _sessionId;

  // Initialize Supabase
  Future<void> initialize() async {
    try {
      _client = Supabase.instance.client;
      print('Using existing Supabase instance');
    } catch (e) {
      print('No existing Supabase instance found');
      try {
        // Initialize a new instance if none exists
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

  // Start streaming IMU data
  Future<void> startIMUStreaming() async {
    if (_isStreaming) return;
    
    _isStreaming = true;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    print('Starting IMU streaming with session ID: $_sessionId');

    // Subscribe to accelerometer data
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) async {
        await _sendIMUData('accelerometer', {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        });
      },
    );

    // Subscribe to gyroscope data
    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) async {
        await _sendIMUData('gyroscope', {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        });
      },
    );

    // Subscribe to magnetometer data
    _magnetometerSubscription = magnetometerEvents.listen(
      (MagnetometerEvent event) async {
        await _sendIMUData('magnetometer', {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        });
      },
    );
  }

  // Stop streaming IMU data
  Future<void> stopIMUStreaming() async {
    if (!_isStreaming) return;
    
    print('Stopping IMU streaming');
    
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;
    
    _isStreaming = false;
    _sessionId = null;
  }

  // Send IMU data to Supabase
  Future<void> _sendIMUData(String sensorType, Map<String, double> data) async {
    try {
      await _client.from('imu_data').insert({
        'session_id': _sessionId,
        'sensor_type': sensorType,
        'x': data['x'],
        'y': data['y'],
        'z': data['z'],
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _client.auth.currentUser?.id,
      });
    } catch (e) {
      print('Error sending IMU data: $e');
    }
  }

  // Get streaming status
  bool get isStreaming => _isStreaming;
  String? get currentSessionId => _sessionId;

  // Get recent IMU data
  Future<List<Map<String, dynamic>>> getRecentIMUData({int limit = 100}) async {
    try {
      final response = await _client
          .from('datatransmission')
          .select()
          .eq('dataid', _client.auth.currentUser?.id ?? '')
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching IMU data: $e');
      return [];
    }
  }

  // Create a session record
  Future<void> createSession() async {
    try {
      await _client.from('sessions').insert({
        'session_id': _sessionId,
        'user_id': _client.auth.currentUser?.id,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
      });
    } catch (e) {
      print('Error creating session: $e');
    }
  }

  // End a session
  Future<void> endSession() async {
    if (_sessionId == null) return;
    
    try {
      await _client.from('sessions').update({
        'end_time': DateTime.now().toIso8601String(),
        'status': 'completed',
      }).eq('session_id', _sessionId!);
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String username,
  }) async {
    try {
      // First, update the user profile
      final supabaseUid = _client.auth.currentUser?.id;
      
      await _client.from('userdetails').upsert({
        'firebasesuid': userId,
        'userid': supabaseUid,
        'name': fullName,
        'username': username,
        'phone': null,  
        'address': null,
        'licensenumber': null,
        'vehicleid': null,
        'creditid': null,
        'rpsid': null,
        'rpsscore': null
      });
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
