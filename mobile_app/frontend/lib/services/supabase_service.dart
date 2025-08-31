import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SupabaseService {
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
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
      anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
    );
    _client = Supabase.instance.client;
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
          .from('imu_data')
          .select()
          .eq('user_id', _client.auth.currentUser?.id ?? '')
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
}
