import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/services/foreground_collection_service.dart';
import 'package:vehnway/services/sensor_service.dart';
import 'package:vehnway/utils/app_logger.dart';

/// Session state that outlives the IMU collector route for camera-off drives.
class ImuCollectionController extends ChangeNotifier {
  final SensorService _sensorService = SensorService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isCollecting = false;
  bool _isStopping = false;
  int _processedCount = 0;
  int _uploadedCount = 0;
  DateTime? _driveStartTime;
  String _sessionId = '';

  ImuCollectionController() {
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  bool get isCollecting => _isCollecting;
  bool get isStopping => _isStopping;
  int get processedCount => _processedCount;
  int get uploadedCount => _uploadedCount;

  Future<bool> start(BuildContext context) async {
    if (_isCollecting || _isStopping) return _isCollecting;

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      CustomSnackBar.showError(
        context,
        'Select a vehicle before starting a drive.',
      );
      return false;
    }

    if (!await ForegroundCollectionService.ensureNotificationPermission()) {
      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Notification permission is required for IMU-only collection.',
        );
      }
      return false;
    }

    var foregroundStarted = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      _driveStartTime = DateTime.now().toUtc();
      _sessionId = const Uuid().v4();
      _processedCount = 0;
      _uploadedCount = 0;

      await _supabase.from(AppConfig.tableSessions).insert({
        'session_id': _sessionId,
        'user_id': user.uid,
        'vehicle_id': vehicleId,
        'start_time': _driveStartTime!.toIso8601String(),
        'status': 'active',
        'distance': 0.0,
      });

      foregroundStarted = await ForegroundCollectionService.start();
      if (!foregroundStarted) {
        throw Exception('Unable to start the foreground collection service');
      }

      if (!context.mounted) {
        throw StateError(
          'Drive screen was closed before collection could start',
        );
      }

      await _sensorService.start(
        context: context,
        sessionId: _sessionId,
        onDataCountUpdate: (processed, uploaded) {
          _processedCount = processed;
          _uploadedCount = uploaded;
          notifyListeners();
        },
      );

      _isCollecting = true;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to start IMU-only collection', error, stackTrace);
      if (foregroundStarted) await ForegroundCollectionService.stop();
      _driveStartTime = null;
      _sessionId = '';
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Failed to start collection: $error');
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> stop([BuildContext? context]) async {
    if (!_isCollecting || _isStopping) return;
    _isStopping = true;
    notifyListeners();

    try {
      await _sensorService.stop(context);
      if (_driveStartTime != null && _sessionId.isNotEmpty) {
        await _supabase
            .from(AppConfig.tableSessions)
            .update({
              'end_time': DateTime.now().toUtc().toIso8601String(),
              'status': 'completed',
            })
            .eq('session_id', _sessionId);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to stop IMU-only collection', error, stackTrace);
      if (context?.mounted ?? false) {
        CustomSnackBar.showError(context!, 'Failed to stop collection: $error');
      }
    } finally {
      await ForegroundCollectionService.stop();
      _isCollecting = false;
      _isStopping = false;
      _driveStartTime = null;
      _sessionId = '';
      notifyListeners();
    }
  }

  void _onForegroundTaskData(Object data) {
    if (data == ForegroundCollectionService.stopActionId) {
      unawaited(stop());
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _sensorService.dispose();
    super.dispose();
  }
}
