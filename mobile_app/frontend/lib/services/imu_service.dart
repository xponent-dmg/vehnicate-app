// // ignore_for_file: deprecated_member_use

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';

// class ImuService {
//   final SupabaseClient _supabase;

//   ImuService({SupabaseClient? supabaseClient}) : _supabase = supabaseClient ?? Supabase.instance.client;

//   final List<Map<String, dynamic>> _imuBuffer = [];
//   StreamSubscription? _accelSub;
//   StreamSubscription? _gyroSub;
//   StreamSubscription? _magSub;
//   StreamSubscription? _userAccelSub;
//   StreamSubscription<Position>? _positionSub;
//   Timer? _uploadTimer;

//   double? _gx, _gy, _gz;
//   double? _mx, _my, _mz;
//   double? _uax, _uay, _uaz;
//   double _latitude = 0.0;
//   double _longitude = 0.0;
//   double _speed = 0.0;

//   bool _isCollecting = false;
//   bool get isCollecting => _isCollecting;

//   // Throttling: Only collect data at 50 samples per second (every ~20ms)
//   DateTime? _lastSampleTime;
//   static const int _sampleIntervalMs = 20; // ~50 samples per second
//   static const Duration _sensorInterval = Duration(milliseconds: 20); // Set sensor sampling rate

//   // Data count tracking
//   int _processedCount = 0;
//   int _uploadedCount = 0;

//   // Callbacks for UI updates
//   Function(int processed, int uploaded)? onDataCountUpdate;

//   Future<void> _ensureLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied, cannot request.');
//     }
//   }

//   Future<void> start({
//     required BuildContext context,
//     Position? Function()? getCurrentPosition,
//     bool manageLocationStream = false,
//     bool useUserAccelerometer = false,
//     Function(int processed, int uploaded)? onDataCountUpdate,
//   }) async {
//     print('[IMU_DEBUG][start] Called');
//     if (_isCollecting) return;

//     if (manageLocationStream) {
//       await _ensureLocationPermission();
//     }

//     final vehicleId = context.read<VehicleProvider>().vehicleId;
//     print('[IMU_DEBUG][start] Vehicle ID: $vehicleId');
//     _isCollecting = true;
//     this.onDataCountUpdate = onDataCountUpdate;

//     if (!context.mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('📱 Started sensor data collection (background mode enabled)'),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 2),
//       ),
//     );

//     _gyroSub = gyroscopeEventStream(samplingPeriod: _sensorInterval).listen((GyroscopeEvent event) {
//       _gx = event.x;
//       _gy = event.y;
//       _gz = event.z;
//     });

//     // Magnetometer subscription
//     _magSub = magnetometerEventStream(samplingPeriod: _sensorInterval).listen((MagnetometerEvent event) {
//       _mx = event.x;
//       _my = event.y;
//       _mz = event.z;
//     });

//     // User-accelerometer subscription (acceleration without gravity)
//     _userAccelSub = userAccelerometerEventStream(samplingPeriod: _sensorInterval).listen((
//       UserAccelerometerEvent event,
//     ) {
//       _uax = event.x;
//       _uay = event.y;
//       _uaz = event.z;
//     });

//     if (useUserAccelerometer) {
//       _accelSub = userAccelerometerEventStream(samplingPeriod: _sensorInterval).listen((UserAccelerometerEvent event) {
//         // Throttle to 50 samples per second
//         final now = DateTime.now();
//         if (_lastSampleTime != null) {
//           final elapsed = now.difference(_lastSampleTime!).inMilliseconds;
//           if (elapsed < _sampleIntervalMs) {
//             return; // Skip this event
//           }
//           // Debug: log actual sampling rate every 50 samples
//           if (_processedCount > 0 && _processedCount % 50 == 0) {
//             print(
//               '[IMU_DEBUG] Actual interval: ${elapsed}ms (target: ${_sampleIntervalMs}ms), Rate: ${(1000 / elapsed).toStringAsFixed(1)} Hz',
//             );
//           }
//         }
//         _lastSampleTime = now;

//         final Position? pos = getCurrentPosition != null ? getCurrentPosition() : null;
//         final imuData = {
//           'vehicleid': vehicleId,
//           'timesent': DateTime.now().toIso8601String(),
//           'accelx': event.x,
//           'accely': event.y,
//           'accelz': event.z,
//           'gyrox': _gx ?? 0,
//           'gyroy': _gy ?? 0,
//           'gyroz': _gz ?? 0,
//           'magx': _mx ?? 0,
//           'magy': _my ?? 0,
//           'magz': _mz ?? 0,
//           'useraccelx': _uax ?? 0,
//           'useraccely': _uay ?? 0,
//           'useraccelz': _uaz ?? 0,
//           'latitude': pos?.latitude ?? _latitude,
//           'longitude': pos?.longitude ?? _longitude,
//           'speed': pos?.speed ?? _speed,
//         };
//         _imuBuffer.add(imuData);
//         _processedCount++;
//         onDataCountUpdate?.call(_processedCount, _uploadedCount);
//       });
//     } else {
//       _accelSub = accelerometerEventStream(samplingPeriod: _sensorInterval).listen((AccelerometerEvent event) {
//         // Throttle to 50 samples per second
//         final now = DateTime.now();
//         if (_lastSampleTime != null) {
//           final elapsed = now.difference(_lastSampleTime!).inMilliseconds;
//           if (elapsed < _sampleIntervalMs) {
//             return; // Skip this event
//           }
//           // Debug: log actual sampling rate every 50 samples
//           if (_processedCount > 0 && _processedCount % 50 == 0) {
//             print(
//               '[IMU_DEBUG] Actual interval: ${elapsed}ms (target: ${_sampleIntervalMs}ms), Rate: ${(1000 / elapsed).toStringAsFixed(1)} Hz',
//             );
//           }
//         }
//         _lastSampleTime = now;

//         final Position? pos = getCurrentPosition != null ? getCurrentPosition() : null;
//         final imuData = {
//           'vehicleid': context.read<VehicleProvider>().vehicleId,
//           'timesent': DateTime.now().toIso8601String(),
//           'accelx': event.x,
//           'accely': event.y,
//           'accelz': event.z,
//           'gyrox': _gx ?? 0,
//           'gyroy': _gy ?? 0,
//           'gyroz': _gz ?? 0,
//           'magx': _mx ?? 0,
//           'magy': _my ?? 0,
//           'magz': _mz ?? 0,
//           'useraccelx': _uax ?? 0,
//           'useraccely': _uay ?? 0,
//           'useraccelz': _uaz ?? 0,
//           'latitude': pos?.latitude ?? _latitude,
//           'longitude': pos?.longitude ?? _longitude,
//           'speed': pos?.speed ?? _speed,
//         };
//         _imuBuffer.add(imuData);
//         _processedCount++;
//         onDataCountUpdate?.call(_processedCount, _uploadedCount);
//       });
//     }

//     if (manageLocationStream) {
//       _positionSub = Geolocator.getPositionStream(
//         locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1),
//       ).listen((Position position) {
//         _latitude = position.latitude;
//         _longitude = position.longitude;
//         _speed = position.speed;
//       });
//     }

//     _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
//       if (_imuBuffer.isNotEmpty) {
//         final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
//         _imuBuffer.clear();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('📤 Uploaded ${temp.length} sensor records'),
//             backgroundColor: Colors.blue,
//             duration: const Duration(seconds: 1),
//           ),
//         );
//         await _sendToSupabase(context: context, data: temp);
//         _uploadedCount += temp.length;
//         onDataCountUpdate?.call(_processedCount, _uploadedCount);
//       }
//     });
//   }

//   Future<void> stop(BuildContext context) async {
//     print('[IMU_DEBUG][stop] Called');
//     _accelSub?.cancel();
//     _gyroSub?.cancel();
//     _magSub?.cancel();
//     _userAccelSub?.cancel();
//     _positionSub?.cancel();
//     _uploadTimer?.cancel();
//     _isCollecting = false;
//     _lastSampleTime = null; // Reset throttle timer

//     if (_imuBuffer.isNotEmpty) {
//       final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
//       _imuBuffer.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('📤 Uploaded ${temp.length} sensor records'),
//           backgroundColor: Colors.blue,
//           duration: const Duration(seconds: 1),
//         ),
//       );
//       await _sendToSupabase(context: context, data: temp);
//       _uploadedCount += temp.length;
//       onDataCountUpdate?.call(_processedCount, _uploadedCount);
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('⏹️ Stopped sensor data collection'),
//         backgroundColor: Colors.orange,
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }

//   Future<void> _sendToSupabase({required BuildContext context, required List<Map<String, dynamic>> data}) async {
//     try {
//       final transformedData =
//           data.map((item) {
//             return {
//               'vehicleid': item['vehicleid'],
//               'timesent': item['timesent'],
//               'accelx': item['accelx'],
//               'accely': item['accely'],
//               'accelz': item['accelz'],
//               'gyrox': item['gyrox'],
//               'gyroy': item['gyroy'],
//               'gyroz': item['gyroz'],
//               'magx': item['magx'],
//               'magy': item['magy'],
//               'magz': item['magz'],
//               'useraccelx': item['useraccelx'],
//               'useraccely': item['useraccely'],
//               'useraccelz': item['useraccelz'],
//               'latitude': item['latitude'],
//               'longitude': item['longitude'],
//               'speed': item['speed'],
//             };
//           }).toList();

//       await _supabase.from('datatransmission').insert(transformedData);
//     } on PostgrestException catch (e) {
//       String errorMessage = 'Database error';
//       if (e.code == '23503') {
//         errorMessage = 'Invalid vehicle ID. Please check your vehicle settings.';
//       } else if (e.code == '42501') {
//         errorMessage = 'Permission denied. Please check your login.';
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
//       );
//       _imuBuffer.addAll(data);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Upload failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//       _imuBuffer.addAll(data);
//     }
//   }

//   void dispose() {
//     _accelSub?.cancel();
//     _gyroSub?.cancel();
//     _magSub?.cancel();
//     _userAccelSub?.cancel();
//     _positionSub?.cancel();
//     _uploadTimer?.cancel();
//   }
// }
