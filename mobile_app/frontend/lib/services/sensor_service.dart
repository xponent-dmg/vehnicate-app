import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import '../models/sensor_data.dart';
import '../Widgets/custom_snackbar.dart';

/// Service for managing sensor data streaming from native platform.
class SensorService {
  static const EventChannel _eventChannel = EventChannel('vehnicate/sensors');
  final SupabaseClient _supabase;

  SensorService({SupabaseClient? supabaseClient}) : _supabase = supabaseClient ?? Supabase.instance.client;

  StreamSubscription? _subscription;
  final StreamController<SensorPacket> _controller = StreamController<SensorPacket>.broadcast();

  // Data buffering and uploading
  final List<Map<String, dynamic>> _imuBuffer = [];
  Timer? _uploadTimer;
  int _processedCount = 0;
  int _uploadedCount = 0;
  bool _isCollecting = false;
  bool get isCollecting => _isCollecting;

  // Throttling
  DateTime? _lastSampleTime;
  static const int _sampleIntervalMs = 10; // ~100 samples per second

  // Callbacks
  Function(int processed, int uploaded)? onDataCountUpdate;

  /// Exposes the sensor data stream
  Stream<SensorPacket> get sensorStream => _controller.stream;

  /// Starts listening to sensor data from native platform and uploads to Supabase
  Future<void> start({required BuildContext context, Function(int processed, int uploaded)? onDataCountUpdate}) async {
    if (_isCollecting) return;

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      CustomSnackBar.showError(context, 'No vehicle selected! Please go to Garage and select a vehicle.');
      return;
    }

    _isCollecting = true;
    this.onDataCountUpdate = onDataCountUpdate;

    if (context.mounted) {
      CustomSnackBar.showSuccess(context, '📱 Started sensor data collection');
    }

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final packet = SensorPacket.fromMap(event as Map<dynamic, dynamic>);
          _controller.add(packet);

          // Throttle processing
          final now = DateTime.now();
          if (_lastSampleTime != null) {
            final elapsed = now.difference(_lastSampleTime!).inMilliseconds;
            if (elapsed < _sampleIntervalMs) {
              return; // Skip this event
            }
          }
          _lastSampleTime = now;

          // Buffer data
          final imuData = {
            'vehicleid': vehicleId,
            'timesent': DateTime.now().toIso8601String(),
            'accelx': packet.raw.ax,
            'accely': packet.raw.ay,
            'accelz': packet.raw.az,
            'gyrox': packet.raw.Gx,
            'gyroy': packet.raw.Gy,
            'gyroz': packet.raw.Gz,
            'magx': packet.raw.Mx,
            'magy': packet.raw.My,
            'magz': packet.raw.Mz,
            'useraccelx': packet.raw.Ax,
            'useraccely': packet.raw.Ay,
            'useraccelz': packet.raw.Az,
            'latitude': packet.location.latitude,
            'longitude': packet.location.longitude,
            'pitch': packet.angles.theta,
            'roll': packet.angles.phi,
            'yaw': 0.0, // Yaw not available in angles, setting to 0.0
          };
          _imuBuffer.add(imuData);
          _processedCount++;
          this.onDataCountUpdate?.call(_processedCount, _uploadedCount);
        } catch (e) {
          _controller.addError(e);
          print('Error processing sensor event: $e');
        }
      },
      onError: (dynamic error) {
        _controller.addError(error);
        print('Sensor stream error: $error');
      },
    );

    // Start upload timer
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_imuBuffer.isNotEmpty && context.mounted) {
        final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
        _imuBuffer.clear();

        CustomSnackBar.showInfo(context, '📤 Uploaded ${temp.length} sensor records');

        await _sendToSupabase(context: context, data: temp);
        _uploadedCount += temp.length;
        this.onDataCountUpdate?.call(_processedCount, _uploadedCount);
      }
    });
  }

  /// Stops listening to sensor data
  Future<void> stop(BuildContext context) async {
    _subscription?.cancel();
    _subscription = null;
    _uploadTimer?.cancel();
    _isCollecting = false;
    _lastSampleTime = null;

    if (_imuBuffer.isNotEmpty) {
      final List<Map<String, dynamic>> temp = List.from(_imuBuffer);
      _imuBuffer.clear();

      if (context.mounted) {
        CustomSnackBar.showInfo(context, '📤 Uploaded ${temp.length} sensor records');
      }

      await _sendToSupabase(context: context, data: temp);
      _uploadedCount += temp.length;
      onDataCountUpdate?.call(_processedCount, _uploadedCount);
    }

    if (context.mounted) {
      CustomSnackBar.showWarning(context, '⏹️ Stopped sensor data collection');
    }
  }

  Future<void> _sendToSupabase({required BuildContext context, required List<Map<String, dynamic>> data}) async {
    try {
      // Data is already in the correct format for the table
      await _supabase.from('datatransmission').insert(data);
    } on PostgrestException catch (e) {
      String errorMessage = 'Database error';
      if (e.code == '23503') {
        errorMessage = 'Invalid vehicle ID. Please check your vehicle settings.';
      } else if (e.code == '42501') {
        errorMessage = 'Permission denied. Please check your login.';
      }
      if (context.mounted) {
        CustomSnackBar.showError(context, '❌ $errorMessage');
      }
      // Re-add failed data to buffer? Or just log it?
      // Original code re-added it, so we will too.
      _imuBuffer.addAll(data);
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, '❌ Upload failed: ${e.toString()}');
      }
      _imuBuffer.addAll(data);
    }
  }

  /// Disposes resources
  void dispose() {
    stopListening();
    _controller.close();
    _uploadTimer?.cancel();
  }

  // Helper to stop listening without UI feedback (internal use or if needed)
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
