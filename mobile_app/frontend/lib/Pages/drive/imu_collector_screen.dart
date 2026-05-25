// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/services/camera_service_rgb.dart';
import 'package:vehnway/services/device_id_service.dart';
import 'package:vehnway/services/sensor_service.dart';
import 'package:vehnway/Widgets/form_overlay.dart';
import 'package:location/location.dart' as loc;
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';

class ImuCollector extends StatefulWidget {
  const ImuCollector({super.key});

  @override
  State<ImuCollector> createState() => _ImuCollectorState();
}

class _ImuCollectorState extends State<ImuCollector> {
  final SensorService _sensorService = SensorService();
  final CameraServiceRGB _cameraService = CameraServiceRGB();
  final DeviceIdService _deviceIdService = DeviceIdService();
  final supabase = Supabase.instance.client;

  // Collection state
  bool isCollecting = false;
  bool isStopping = false;

  // Data collection state
  int _imuDataCount = 0;
  int _uploadedImuCount = 0;

  // Time tracking
  DateTime? _driveStartTime;
  DateTime? _driveEndTime;

  // Config
  String _deviceId = 'pending...';
  String _sessionId = '';

  // Start position coordinates
  double? _startX;
  double? _startY;
  double? _startZ;

  @override
  void initState() {
    super.initState();
    AppLogger.info('ImuCollector initialized');
    _initAll();

    // Listen to camera service stats updates
    _cameraService.onStatsUpdated = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _initAll() async {
    try {
      AppLogger.info('Initializing ImuCollector components...');
      _deviceId = await _deviceIdService.getPersistentDeviceId();
      AppLogger.info('Persistent Device ID: $_deviceId');

      await _initCamera();
      await _initLocation();
      AppLogger.info(
        'ImuCollector initialized successfully with deviceId: $_deviceId',
      );
    } catch (e, st) {
      AppLogger.error('ImuCollector initialization failed', e, st);
      CustomSnackBar.showError(context, 'Initialization failed: $e');
    }
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) setState(() {}); // Rebuild to show preview
    } catch (e) {
      CustomSnackBar.showError(context, 'Camera initialization failed: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
    } catch (e) {
      CustomSnackBar.showError(context, 'Location initialization failed: $e');
    }
  }

  Future<bool> _showStartPositionDialog() async {
    final TextEditingController xController = TextEditingController();
    final TextEditingController yController = TextEditingController();
    final TextEditingController zController = TextEditingController();

    // Flag to track if the form was successfully submitted
    bool success = false;

    await FormOverlay.show(
      context: context,
      title: 'Enter Start Position',
      submitButtonText: 'Start Collection',
      fields: [
        FormFieldConfig(
          label: 'Start X',
          hint: '0.0',
          icon: Icons.location_on_outlined,
          controller: xController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
        FormFieldConfig(
          label: 'Start Y',
          hint: '0.0',
          icon: Icons.location_on_outlined,
          controller: yController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
        FormFieldConfig(
          label: 'Start Z',
          hint: '0.0',
          icon: Icons.height,
          controller: zController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      ],
      onSubmit: () async {
        // Validate inputs
        final x = double.tryParse(xController.text);
        final y = double.tryParse(yController.text);
        final z = double.tryParse(zController.text);

        if (x == null || y == null || z == null) {
          throw 'Please enter valid numeric values for X, Y, and Z';
        }

        _startX = x;
        _startY = y;
        _startZ = z;
        success = true;
      },
      onError: (error) {
        CustomSnackBar.showError(context, error.toString());
      },
    );

    return success;
  }

  void startCollection() async {
    if (isCollecting) return;

    // 1. Request Location Service (Gated)
    // Use location package to trigger the native Google Play Services popup
    final loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            'Location services are required to start collection.',
          );
        }
        return;
      }
    }

    // 2. Enable Wakelock
    await WakelockPlus.enable();

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Error: No vehicle selected. Please go to Garage and select a vehicle.',
        );
      }
      await WakelockPlus.disable();
      return;
    }

    // Show dialog to get start position before starting collection
    final confirmed = await _showStartPositionDialog();
    if (!confirmed) {
      await WakelockPlus.disable();
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Capture start time
      _driveStartTime = DateTime.now().toLocal();

      // Generate session UUID
      _sessionId = const Uuid().v4();

      // Create session in database first (so frames can reference it)
      await supabase.from(AppConfig.tableSessions).insert({
        'session_id': _sessionId,
        'user_id': currentUser.uid,
        'vehicle_id': vehicleId,
        'start_time': _driveStartTime!.toIso8601String(),
        'status': 'active',
        'distance': 0.0,
      });

      // Start Sensor collection
      await _sensorService.start(
        context: context,
        sessionId: _sessionId,
        onDataCountUpdate: (processed, uploaded) {
          if (mounted) {
            setState(() {
              _imuDataCount = processed;
              _uploadedImuCount = uploaded;
            });
          }
        },
      );

      // Start camera streaming
      await _cameraService.startStreaming(
        vehicleId: vehicleId.toString(), // Ensure string
        deviceId: _deviceId,
        sessionId: _sessionId,
      );

      setState(() => isCollecting = true);
      // CustomSnackBar.showSuccess(context, 'Data collection started!');
    } catch (e, st) {
      AppLogger.error('Failed to start collection', e, st);
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to start collection: $e');
      }
      _driveStartTime = null; // Reset if failed
      // CustomSnackBar.showError(context, 'Failed to start collection: $e');
      await WakelockPlus.disable();
    }
  }

  void stopCollection() async {
    if (isStopping) return;

    setState(() {
      isStopping = true;
    });

    try {
      // Capture end time
      _driveEndTime = DateTime.now().toLocal();

      // Stop Sensor collection and Camera streaming in parallel
      await Future.wait([
        _sensorService.stop(context),
        _cameraService.stopStreaming(),
      ]);

      // Send start and end times to backend
      if (_driveStartTime != null && _driveEndTime != null) {
        await _saveDriveSession();
      }

      if (mounted) {
        setState(() {
          isCollecting = false;
          isStopping = false;
        });
      }

      await WakelockPlus.disable();

      // CustomSnackBar.showSuccess(context, 'Data collection stopped!');
    } catch (e, st) {
      AppLogger.error('Error stopping collection', e, st);
      if (mounted) {
        setState(() {
          isStopping = false;
        });
      }
      await WakelockPlus.disable();
    }
  }

  Future<void> _saveDriveSession() async {
    try {
      if (_driveStartTime == null || _driveEndTime == null) {
        return;
      }

      // Update existing session
      await supabase
          .from(AppConfig.tableSessions)
          .update({
            'end_time': _driveEndTime!.toIso8601String(),
            'status': 'completed',
          })
          .eq('session_id', _sessionId);
    } catch (e, st) {
      AppLogger.error('Failed to save drive session times', e, st);
      if (mounted) {
        CustomSnackBar.showWarning(
          context,
          'Warning: Failed to save drive session times',
        );
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _cameraService.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isCollecting,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        // Show confirmation dialog if collection is active
        if (isCollecting) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Stop Data Collection?'),
                content: const Text(
                  'Data transmission is currently active. Going back will stop the transmission. Do you want to continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Stop & Go Back'),
                  ),
                ],
              );
            },
          );

          if (shouldPop == true && mounted) {
            stopCollection();
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.mainBackground,
          ),
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout();
              } else {
                return _buildPortraitLayout();
              }
            },
          ),
        ),
      ), // Close Scaffold
    ); // Close PopScope
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.09),
        // Camera Preview
        _buildCameraPreview(height: 400, isLandscape: false),

        // Statistics Display
        _buildStatisticsCard(),

        // Control Buttons
        _buildControlButtons(),

        const Spacer(),

        // Status Indicator
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side: Camera Preview
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildCameraPreview(isLandscape: true)),
              _buildStatusIndicator(),
            ],
          ),
        ),

        // Right side: Statistics and Controls
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatisticsCard(),
                const SizedBox(height: 12),
                _buildControlButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview({double? height, bool isLandscape = false}) {
    if (_cameraService.isReady && _cameraService.controller != null) {
      // Use reciprocal aspect ratio for landscape mode
      final aspectRatio =
          isLandscape
              ? _cameraService.controller!.value.aspectRatio
              : 1 / _cameraService.controller!.value.aspectRatio;

      return Container(
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white24,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: CameraPreview(_cameraService.controller!),
          ),
        ),
      );
    } else {
      return Container(
        height: height ?? 200,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.darkBackground,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 48, color: Colors.white38),
              SizedBox(height: 8),
              Text('Camera not ready', style: TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Data Collection Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'IMU Data',
                '${_imuDataCount - _uploadedImuCount}',
                '$_uploadedImuCount',
              ),
              _buildStatCard(
                'Images',
                '${_cameraService.processedCount - _cameraService.uploadedCount}',
                '${_cameraService.uploadedCount}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pending Images: ${_cameraService.pendingFramesCount}',
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  (isCollecting && !isStopping)
                      ? stopCollection
                      : (!isCollecting ? startCollection : null),
              icon:
                  isStopping
                      ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : Icon(isCollecting ? Icons.stop : Icons.play_arrow),
              label: Text(
                isStopping
                    ? 'Stopping...'
                    : (isCollecting ? 'Stop Collection' : 'Start Collection'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCollecting ? AppColors.danger : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _cameraService.uploadBatch();
                CustomSnackBar.showSuccess(context, 'Upload triggered');
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_cameraService.pendingFramesCount == 0)
                        ? Colors.grey
                        : AppColors.mutedPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCollecting
                ? AppColors.success.withOpacity(0.2)
                : AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCollecting ? AppColors.success : Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCollecting
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isCollecting ? AppColors.success : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            isCollecting ? 'Data Collection Active' : 'Data Collection Stopped',
            style: TextStyle(
              color: isCollecting ? AppColors.success : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String processed, String uploaded) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          processed,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Uploaded: $uploaded',
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }
}
