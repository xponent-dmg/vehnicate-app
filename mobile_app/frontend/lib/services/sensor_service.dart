import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import '../models/sensor_data.dart';
import '../Widgets/custom_snackbar.dart';

class SensorService {
  static const EventChannel _eventChannel = EventChannel('vehnicate/sensors');
  final SupabaseClient _supabase;

  SensorService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  StreamSubscription? _subscription;
  final StreamController<SensorPacket> _controller =
      StreamController<SensorPacket>.broadcast();

  // --- Robust Buffer Management ---
  final List<Map<String, dynamic>> _imuBuffer = [];
  final int _maxBufferSize = 10000; // Cap to prevent OOM (Out of Memory)
  bool _isUploading = false; // The "Lock"

  Timer? _uploadTimer;
  int _processedCount = 0;
  int _uploadedCount = 0;
  bool _isCollecting = false;

  bool get isCollecting => _isCollecting;
  Stream<SensorPacket> get sensorStream => _controller.stream;
  Function(int processed, int uploaded)? onDataCountUpdate;

  // static const int _sampleIntervalMs = 10; // Adjusted for ~100Hz stability

  Future<void> start({
    required BuildContext context,
    Function(int processed, int uploaded)? onDataCountUpdate,
  }) async {
    if (_isCollecting) return;

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      CustomSnackBar.showError(context, 'No vehicle selected!');
      return;
    }

    _isCollecting = true;
    _processedCount = 0; // Reset counters on new session
    _uploadedCount = 0;
    this.onDataCountUpdate = onDataCountUpdate;

    _subscription = _eventChannel.receiveBroadcastStream().listen((
      dynamic event,
    ) {
      try {
        final packet = SensorPacket.fromMap(event as Map<dynamic, dynamic>);
        _controller.add(packet);

        // Buffer logic
        if (_imuBuffer.length < _maxBufferSize) {
          _imuBuffer.add({
            'vehicleid': vehicleId,
            'timesent':
                DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 5, minutes: 30))
                    .toIso8601String(), // Use UTC for DB consistency
            'accelx': packet.raw.ax,
            'accely': packet.raw.ay,
            'accelz': packet.raw.az,
            'gyrox': packet.raw.Gx,
            'gyroy': packet.raw.Gy,
            'gyroz': packet.raw.Gz,
            'magx': packet.raw.Mx, 'magy': packet.raw.My, 'magz': packet.raw.Mz,
            'useraccelx': packet.raw.Ax,
            'useraccely': packet.raw.Ay,
            'useraccelz': packet.raw.Az,
            'latitude': packet.location.latitude,
            'longitude': packet.location.longitude,
            'speed': packet.location.speed,
            'bearing': packet.location.bearing,
          });
          _processedCount++;
          this.onDataCountUpdate?.call(_processedCount, _uploadedCount);
        } else {
          // Optional: Remove oldest record to make room for newest (FIFO)
          _imuBuffer.removeAt(0);
        }
      } catch (e) {
        _controller.addError(e);
      }
    });

    // Periodic Upload Loop
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _attemptUpload(context);
    });
  }

  Future<void> _attemptUpload(BuildContext context) async {
    // 1. Check if we are already uploading or have nothing to send
    if (_isUploading || _imuBuffer.isEmpty) return;

    _isUploading = true;

    // 2. Snaphot the current buffer and clear it immediately
    // This prevents the "retry loop" from duplicating data
    final List<Map<String, dynamic>> dataToUpload = List.from(_imuBuffer);
    _imuBuffer.clear();

    try {
      await _supabase.from('datatransmission').insert(dataToUpload);

      // 3. Only update uploaded count on SUCCESS
      _uploadedCount += dataToUpload.length;
      onDataCountUpdate?.call(_processedCount, _uploadedCount);

      if (context.mounted) {
        CustomSnackBar.showInfo(
          context,
          'Synced ${dataToUpload.length} records',
        );
      }
    } catch (e) {      // 4. On failure, put data back at the START of the buffer if there's room
      if (_imuBuffer.length + dataToUpload.length < _maxBufferSize) {
        _imuBuffer.insertAll(0, dataToUpload);
      }

      if (context.mounted) {
        CustomSnackBar.showWarning(
          context,
          'Connection weak. Retrying later...',
        );
      }
    } finally {
      _isUploading = false; // Release the lock
    }
  }

  Future<void> stop(BuildContext context) async {
    _subscription?.cancel();
    _uploadTimer?.cancel();
    _isCollecting = false;

    // Final Flush
    if (_imuBuffer.isNotEmpty) {
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
