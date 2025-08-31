import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000'; // Your computer's IP address
  // Alternative IPs if the above doesn't work:
  // static const String baseUrl = 'http://192.168.56.1:3000';
  // static const String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator only
  
  // Get Firebase Auth token
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Common headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Health check
  Future<Map<String, dynamic>?> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Health check error: $e');
    }
    return null;
  }

  // Start session
  Future<String?> startSession(String vehicleId, String startLocation) async {
    try {
      final headers = await _getHeaders();
      print('Starting session with headers: $headers');
      print('Request body: vehicleid=$vehicleId, startLocation=$startLocation');
      
      final response = await http.post(
        Uri.parse('$baseUrl/session/start'),
        headers: headers,
        body: json.encode({
          'vehicleid': vehicleId,
          'startLocation': startLocation,
        }),
      );
      
      print('Start session response status: ${response.statusCode}');
      print('Start session response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sessionId'].toString();
      }
      print('Start session error: Status ${response.statusCode}, Body: ${response.body}');
    } catch (e) {
      print('Start session error: $e');
    }
    return null;
  }

  // Stop session
  Future<bool> stopSession(String sessionId, String endLocation) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/session/stop'),
        headers: headers,
        body: json.encode({
          'sessionId': sessionId,
          'endLocation': endLocation,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Stop session error: $e');
    }
    return false;
  }

  // Upload IMU data
  Future<bool> uploadIMUData({
    required String vehicleId,
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double latitude,
    required double longitude,
    required double speed,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/imu/upload'),
        headers: headers,
        body: json.encode({
          'vehicleid': vehicleId,
          'accelx': accelX,
          'accely': accelY,
          'accelz': accelZ,
          'gyrox': gyroX,
          'gyroy': gyroY,
          'gyroz': gyroZ,
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Upload IMU data error: $e');
    }
    return false;
  }

  // Get RPS score
  Future<double?> getRPSScore() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rps'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rps'] != null && data['rps'].isNotEmpty) {
          return data['rps'][0]['score']?.toDouble();
        }
      }
    } catch (e) {
      print('Get RPS error: $e');
    }
    return null;
  }

  // Get user stats
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/stats'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stats'];
      }
    } catch (e) {
      print('Get user stats error: $e');
    }
    return null;
  }
}

class IMUDataService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static StreamSubscription<Position>? _locationSubscription;
  
  static AccelerometerEvent? _lastAccelData;
  static GyroscopeEvent? _lastGyroData;
  static Position? _lastLocationData;
  
  static final ApiService _apiService = ApiService();
  static Timer? _uploadTimer;
  static String? _currentSessionId;
  static String? _vehicleId;

  // Start collecting IMU data
  static Future<bool> startDataCollection(String vehicleId) async {
    _vehicleId = vehicleId;
    
    print('Starting data collection for vehicle: $vehicleId');
    
    // Check if backend is reachable
    final apiService = ApiService();
    final healthCheck = await apiService.healthCheck();
    if (healthCheck == null) {
      print('Backend is not reachable at ${ApiService.baseUrl}');
      return false;
    }
    print('Backend health check passed: $healthCheck');
    
    // Request location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }
    print('Location services are enabled');

    LocationPermission permission = await Geolocator.checkPermission();
    print('Current location permission: $permission');
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('Requested location permission: $permission');
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    print('Getting current position...');
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Current position obtained: ${currentPosition.latitude}, ${currentPosition.longitude}');
      
      String startLocation = '${currentPosition.latitude},${currentPosition.longitude}';
      print('Starting session with location: $startLocation');
      
      _currentSessionId = await apiService.startSession(vehicleId, startLocation);
      print('Session started with ID: $_currentSessionId');
      
    } catch (e) {
      print('Error getting current position: $e');
      return false;
    }
    
    if (_currentSessionId == null) {
      print('Failed to start session');
      return false;
    }

    // Start sensor streams
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _lastAccelData = event;
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _lastGyroData = event;
    });

    // Start location stream
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _lastLocationData = position;
    });

    // Start periodic upload (every 5 seconds)
    _uploadTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _uploadCurrentData();
    });

    print('IMU data collection started with session ID: $_currentSessionId');
    return true;
  }

  // Stop collecting IMU data
  static Future<void> stopDataCollection() async {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _uploadTimer?.cancel();

    if (_currentSessionId != null && _lastLocationData != null) {
      String endLocation = '${_lastLocationData!.latitude},${_lastLocationData!.longitude}';
      await _apiService.stopSession(_currentSessionId!, endLocation);
    }

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _locationSubscription = null;
    _uploadTimer = null;
    _currentSessionId = null;
    _vehicleId = null;

    print('IMU data collection stopped');
  }

  // Upload current sensor data
  static Future<void> _uploadCurrentData() async {
    if (_lastAccelData == null || _lastGyroData == null || _lastLocationData == null || _vehicleId == null) {
      return;
    }

    bool success = await _apiService.uploadIMUData(
      vehicleId: _vehicleId!,
      accelX: _lastAccelData!.x,
      accelY: _lastAccelData!.y,
      accelZ: _lastAccelData!.z,
      gyroX: _lastGyroData!.x,
      gyroY: _lastGyroData!.y,
      gyroZ: _lastGyroData!.z,
      latitude: _lastLocationData!.latitude,
      longitude: _lastLocationData!.longitude,
      speed: _lastLocationData!.speed,
    );

    if (success) {
      print('IMU data uploaded successfully');
    } else {
      print('Failed to upload IMU data');
    }
  }

  // Check if data collection is active
  static bool get isActive => _uploadTimer?.isActive == true;
}

