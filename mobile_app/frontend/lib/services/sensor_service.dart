import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
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

  Future<void> start({
    required BuildContext context,
    Function(int processed, int uploaded)? onDataCountUpdate,
  }) async {
    if (_isCollecting) return;

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      AppLogger.warning('SensorService: No vehicle selected!');
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
                    .toLocal()
                    .add(const Duration(hours: 5, minutes: 30))
                    .toIso8601String(), // Use local time as requested by existing logic
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
          // FIFO: Remove oldest record to make room for newest
          _imuBuffer.removeAt(0);
          AppLogger.warning(
            'SensorService: IMU Buffer overflow, discarding oldest data',
          );
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

    AppLogger.info('SensorService started for vehicle $vehicleId');
  }

  Future<void> _attemptUpload(BuildContext context) async {
    // 1. Check if we are already uploading or have nothing to send
    if (_isUploading || _imuBuffer.isEmpty) return;

    _isUploading = true;

    // 2. Snapshot the current buffer and clear it immediately
    final List<Map<String, dynamic>> dataToUpload = List.from(_imuBuffer);
    _imuBuffer.clear();

    try {
      await _supabase
          .from(AppConfig.tableDataTransmission)
          .insert(dataToUpload);

      // 3. Only update uploaded count on SUCCESS
      _uploadedCount += dataToUpload.length;
      onDataCountUpdate?.call(_processedCount, _uploadedCount);

      AppLogger.info(
        'Synced ${dataToUpload.length} sensor records to Supabase',
      );
    } catch (e, stack) {
      // 4. On failure, put data back at the START of the buffer if there's room
      if (_imuBuffer.length + dataToUpload.length < _maxBufferSize) {
        _imuBuffer.insertAll(0, dataToUpload);
      }

      AppLogger.warning(
        'Sensor upload failed, pending retry: ${dataToUpload.length} records',
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
