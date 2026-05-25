import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';
import '../models/sensor_data.dart';
import '../Widgets/custom_snackbar.dart';

class SensorService {
  static const EventChannel _eventChannel = EventChannel('vehnway/sensors');
  final SupabaseClient _supabase;

  SensorService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  StreamSubscription? _subscription;
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

  // --- Robust Buffer Management ---
  final List<Map<String, dynamic>> _imuBuffer = [];
  final List<Map<String, dynamic>> _gpsBuffer = [];
  final int _maxBufferSize = 10000; // Cap to prevent OOM
  bool _isUploading = false; // The "Lock"

  Timer? _uploadTimer;
  int _processedCount = 0;
  int _uploadedCount = 0;
  bool _isCollecting = false;
  String? _sessionId;

  bool get isCollecting => _isCollecting;
  Stream<dynamic> get sensorStream => _controller.stream;
  Function(int processed, int uploaded)? onDataCountUpdate;

  Future<void> start({
    required BuildContext context,
    required String sessionId,
    Function(int processed, int uploaded)? onDataCountUpdate,
  }) async {
    if (_isCollecting) return;

    _sessionId = sessionId;
    _isCollecting = true;
    _processedCount = 0; // Reset counters on new session
    _uploadedCount = 0;
    this.onDataCountUpdate = onDataCountUpdate;

    _subscription = _eventChannel.receiveBroadcastStream().listen((
      dynamic event,
    ) {
      try {
        final map = event as Map<dynamic, dynamic>;
        _controller.add(map);

        if (map['type'] == 'imu') {
          final imuData = ImuData.fromMap(map);
          if (_imuBuffer.length < _maxBufferSize) {
            _imuBuffer.add({
              'session_id': _sessionId,
              'timestamp_ms': imuData.timestamp,
              'accel_x': imuData.ax,
              'accel_y': imuData.ay,
              'accel_z': imuData.az,
              'gyro_x': imuData.gx,
              'gyro_y': imuData.gy,
              'gyro_z': imuData.gz,
              'user_accel_x': imuData.Ax,
              'user_accel_y': imuData.Ay,
              'user_accel_z': imuData.Az,
            });
            _processedCount++;
            this.onDataCountUpdate?.call(_processedCount, _uploadedCount);
          } else {
            // FIFO: Remove oldest record
            _imuBuffer.removeAt(0);
            AppLogger.warning('SensorService: IMU Buffer overflow, discarding oldest data');
          }
        } else if (map['type'] == 'gps') {
          final gpsData = GpsData.fromMap(map);
          if (_gpsBuffer.length < _maxBufferSize) {
            _gpsBuffer.add({
              'session_id': _sessionId,
              'timestamp_ms': gpsData.timestamp,
              'latitude': gpsData.latitude,
              'longitude': gpsData.longitude,
              'speed': gpsData.speed,
              'bearing': gpsData.bearing,
            });
          } else {
            _gpsBuffer.removeAt(0);
            AppLogger.warning('SensorService: GPS Buffer overflow, discarding oldest data');
          }
        }
      } catch (e, stack) {
        AppLogger.error('Error processing sensor event', e, stack);
        _controller.addError(e);
      }
    });

    // Periodic Upload Loop
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _attemptUpload(context);
    });

    AppLogger.info('SensorService started for session $_sessionId');
  }

  Future<void> _attemptUpload(BuildContext context) async {
    if (_isUploading || (_imuBuffer.isEmpty && _gpsBuffer.isEmpty)) return;

    _isUploading = true;

    // Snapshot the current buffers and clear them immediately
    final List<Map<String, dynamic>> imuDataToUpload = List.from(_imuBuffer);
    final List<Map<String, dynamic>> gpsDataToUpload = List.from(_gpsBuffer);
    
    _imuBuffer.clear();
    _gpsBuffer.clear();

    try {
      if (imuDataToUpload.isNotEmpty) {
        await _supabase
            .from(AppConfig.tableImuData)
            .insert(imuDataToUpload);
        _uploadedCount += imuDataToUpload.length;
      }
      
      if (gpsDataToUpload.isNotEmpty) {
        await _supabase
            .from(AppConfig.tableGpsData)
            .insert(gpsDataToUpload);
      }

      onDataCountUpdate?.call(_processedCount, _uploadedCount);

      AppLogger.info(
        'Synced ${imuDataToUpload.length} IMU records and ${gpsDataToUpload.length} GPS records to Supabase',
      );
    } catch (e, stack) {
      // On failure, put data back at the START of the buffer if there's room
      if (_imuBuffer.length + imuDataToUpload.length < _maxBufferSize) {
        _imuBuffer.insertAll(0, imuDataToUpload);
      }
      if (_gpsBuffer.length + gpsDataToUpload.length < _maxBufferSize) {
        _gpsBuffer.insertAll(0, gpsDataToUpload);
      }

      AppLogger.warning(
        'Sensor upload failed, pending retry: ${imuDataToUpload.length} IMU, ${gpsDataToUpload.length} GPS',
        e,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Sensor data transmission failed',
      );

      if (context.mounted) {
        CustomSnackBar.showWarning(
          context,
          'Connection weak. Retrying Sync...',
        );
      }
    } finally {
      _isUploading = false;
    }
  }

  Future<void> stop(BuildContext context) async {
    _subscription?.cancel();
    _uploadTimer?.cancel();
    _isCollecting = false;

    // Final Flush
    if (_imuBuffer.isNotEmpty || _gpsBuffer.isNotEmpty) {
      await _attemptUpload(context);
    }

    if (context.mounted) {
      CustomSnackBar.showWarning(context, 'Collection stopped');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _uploadTimer?.cancel();
    _controller.close();
  }
}

