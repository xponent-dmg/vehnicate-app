// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

enum AuthProvider { firebase, supabase }

class ImuService {
  final SupabaseClient _supabase;

  ImuService({SupabaseClient? supabaseClient}) : _supabase = supabaseClient ?? Supabase.instance.client;

  final List<Map<String, dynamic>> _imuBuffer = [];
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription<Position>? _positionSub;
  Timer? _uploadTimer;

  double? _gx, _gy, _gz;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _speed = 0.0;

  bool _isCollecting = false;
  bool get isCollecting => _isCollecting;

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, cannot request.');
    }
  }

  Future<void> start({
    required BuildContext context,
    required int vehicleId,
    Position? Function()? getCurrentPosition,
    bool manageLocationStream = false,
    bool useUserAccelerometer = false,
    AuthProvider authProvider = AuthProvider.firebase,
  }) async {
    if (_isCollecting) return;

    if (manageLocationStream) {
      await _ensureLocationPermission();
    }

    _isCollecting = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Started sensor data collection'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    _gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
      _gx = event.x;
      _gy = event.y;
      _gz = event.z;
    });

    if (useUserAccelerometer) {
      _accelSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        final Position? pos = getCurrentPosition != null ? getCurrentPosition() : null;
        final imuData = {
          'vehicleid': vehicleId,
          'timesent': DateTime.now().toIso8601String(),
          'accelx': event.x,
          'accely': event.y,
          'accelz': event.z,
          'gyrox': _gx ?? 0,
          'gyroy': _gy ?? 0,
          'gyroz': _gz ?? 0,
          'latitude': pos?.latitude ?? _latitude,
          'longitude': pos?.longitude ?? _longitude,
          'speed': pos?.speed ?? _speed,
        };
        _imuBuffer.add(imuData);
      });
    } else {
      _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
        final Position? pos = getCurrentPosition != null ? getCurrentPosition() : null;
        final imuData = {
          'vehicleid': vehicleId,
          'timesent': DateTime.now().toIso8601String(),
          'accelx': event.x,
          'accely': event.y,
          'accelz': event.z,
          'gyrox': _gx ?? 0,
          'gyroy': _gy ?? 0,
          'gyroz': _gz ?? 0,
          'latitude': pos?.latitude ?? _latitude,
          'longitude': pos?.longitude ?? _longitude,
          'speed': pos?.speed ?? _speed,
        };
        _imuBuffer.add(imuData);
      });
    }

    if (manageLocationStream) {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1),
      ).listen((Position position) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _speed = position.speed;
      });
    }

    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_imuBuffer.isNotEmpty) {
        final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
        _imuBuffer.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Uploaded ${temp.length} sensor records'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
        await _sendToSupabase(context: context, data: temp, authProvider: authProvider);
      }
    });
  }

  Future<void> stop(BuildContext context, {AuthProvider authProvider = AuthProvider.firebase}) async {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _positionSub?.cancel();
    _uploadTimer?.cancel();
    _isCollecting = false;

    if (_imuBuffer.isNotEmpty) {
      final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
      _imuBuffer.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📤 Uploaded ${temp.length} sensor records'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
      await _sendToSupabase(context: context, data: temp, authProvider: authProvider);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏹️ Stopped sensor data collection'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendToSupabase({
    required BuildContext context,
    required List<Map<String, dynamic>> data,
    required AuthProvider authProvider,
  }) async {
    try {
      if (authProvider == AuthProvider.firebase) {
        final user = fb_auth.FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Please login to upload data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      } else {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Please login to upload data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      final transformedData =
          data.map((item) {
            return {
              'vehicleid': item['vehicleid'],
              'timesent': item['timesent'],
              'accelx': item['accelx'],
              'accely': item['accely'],
              'accelz': item['accelz'],
              'gyrox': item['gyrox'],
              'gyroy': item['gyroy'],
              'gyroz': item['gyroz'],
              'latitude': item['latitude'],
              'longitude': item['longitude'],
              'speed': item['speed'],
            };
          }).toList();

      await _supabase.from('datatransmission').insert(transformedData);
    } on PostgrestException catch (e) {
      String errorMessage = 'Database error';
      if (e.code == '23503') {
        errorMessage = 'Invalid vehicle ID. Please check your vehicle settings.';
      } else if (e.code == '42501') {
        errorMessage = 'Permission denied. Please check your login.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
      );
      _imuBuffer.addAll(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      _imuBuffer.addAll(data);
    }
  }

  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _positionSub?.cancel();
    _uploadTimer?.cancel();
  }
}
