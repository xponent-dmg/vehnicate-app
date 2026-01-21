// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/Widgets/custom_snackbar.dart';
import 'package:vehnicate_frontend/services/camera_service_rgb.dart';
import 'package:vehnicate_frontend/services/sensor_service.dart';

class ImuCollector extends StatefulWidget {
  const ImuCollector({super.key});

  @override
  State<ImuCollector> createState() => _ImuCollectorState();
}

class _ImuCollectorState extends State<ImuCollector> {
  final SensorService _sensorService = SensorService();
  final CameraServiceRGB _cameraService = CameraServiceRGB();
  final supabase = Supabase.instance.client;

  DateTime? _lastSnackAt;
  final int _snackDebounceMs = 2000; // 2 seconds debounce for snackbars

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
  final String _deviceId = 'mobile-device-${DateTime.now().millisecondsSinceEpoch}';
  final String _currentImuBatchId = 'imu-batch-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    print('[IMU_DEBUG][initState] Called');
    _initAll();

    // Listen to camera service stats updates
    _cameraService.onStatsUpdated = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _initAll() async {
    try {
      print('[IMU_DEBUG][_initAll] 🚀 Initializing IMU Collector...');
      await _initCamera();
      await _initLocation();
      print('[IMU_DEBUG][_initAll] ✅ IMU Collector initialized successfully');
    } catch (e, st) {
      print('[IMU_DEBUG][_initAll] ❌ Init error: $e\n$st');
      CustomSnackBar.showError(context, 'Initialization failed: $e');
    }
  }

  Future<void> _initCamera() async {
    print('[IMU_DEBUG][_initCamera] Initializing camera service...');
    try {
      await _cameraService.initialize();
      if (mounted) setState(() {}); // Rebuild to show preview
      print('[IMU_DEBUG][_initCamera] 📷 Camera service initialized successfully');
    } catch (e) {
      print('[IMU_DEBUG][_initCamera] ❌ Camera init error: $e');
      CustomSnackBar.showError(context, 'Camera initialization failed: $e');
    }
  }

  Future<void> _initLocation() async {
    print('[IMU_DEBUG][_initLocation] Initializing location...');
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
      print('[IMU_DEBUG][_initLocation] 📍 Location permissions granted');
    } catch (e) {
      print('[IMU_DEBUG][_initLocation] ❌ Location init error: $e');
      CustomSnackBar.showError(context, 'Location initialization failed: $e');
    }
  }

  void startCollection() async {
    print('[IMU_DEBUG][startCollection] Called');
    if (isCollecting) return;

    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      CustomSnackBar.showError(context, 'Error: No vehicle selected. Please go to Garage and select a vehicle.');
      return;
    }

    try {
      print('[IMU_DEBUG][startCollection] 🔄 Starting data collection...');

      // Capture start time
      _driveStartTime = DateTime.now();
      print('[IMU_DEBUG][startCollection] 📅 Drive started at: $_driveStartTime');

      // Start Sensor collection
      await _sensorService.start(
        context: context,
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
        imuBatchId: _currentImuBatchId,
      );

      setState(() => isCollecting = true);
      print('[IMU_DEBUG][startCollection] ✅ Data collection started successfully');
      // CustomSnackBar.showSuccess(context, 'Data collection started!');
    } catch (e) {
      print('[IMU_DEBUG][startCollection] ❌ Start collection error: $e');
      _showSnack('Failed to start collection: $e');
      _driveStartTime = null; // Reset if failed
      // CustomSnackBar.showError(context, 'Failed to start collection: $e');
    }
  }

  void stopCollection() async {
    print('[IMU_DEBUG][stopCollection] Called');
    if (isStopping) return;

    setState(() {
      isStopping = true;
    });

    try {
      print('[IMU_DEBUG][stopCollection] ⏹️ Stopping data collection...');

      // Capture end time
      _driveEndTime = DateTime.now();
      print('[IMU_DEBUG][stopCollection] 📅 Drive ended at: $_driveEndTime');

      // Stop Sensor collection and Camera streaming in parallel
      await Future.wait([_sensorService.stop(context), _cameraService.stopStreaming()]);

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
      print('[IMU_DEBUG][stopCollection] ✅ Data collection stopped successfully');
      // CustomSnackBar.showSuccess(context, 'Data collection stopped!');
    } catch (e) {
      print('[IMU_DEBUG][stopCollection] ❌ Stop collection error: $e');
      // CustomSnackBar.showError(context, 'Error stopping collection: $e');
      if (mounted) {
        setState(() {
          isStopping = false;
        });
      }
    }
  }

  Future<void> _saveDriveSession() async {
    try {
      final vehicleId = context.read<VehicleProvider>().vehicleId;
      if (vehicleId == null || _driveStartTime == null || _driveEndTime == null) {
        print('[IMU_DEBUG][_saveDriveSession] ⚠️ Missing required data');
        return;
      }

      final duration = _driveEndTime!.difference(_driveStartTime!);
      
      print('[IMU_DEBUG][_saveDriveSession] 💾 Saving drive session...');
      print('[IMU_DEBUG][_saveDriveSession] Start: $_driveStartTime');
      print('[IMU_DEBUG][_saveDriveSession] End: $_driveEndTime');
      print('[IMU_DEBUG][_saveDriveSession] Duration: ${duration.inMinutes} minutes');

      // Save to your existing trips table
      await supabase.from('trips').insert({
        'vehicleid': vehicleId,
        'starttime': _driveStartTime!.toIso8601String(),
        'endtime': _driveEndTime!.toIso8601String(),
        'distance': 0.0, // You can calculate actual distance if you have GPS data
      });

      print('[IMU_DEBUG][_saveDriveSession] ✅ Drive session saved successfully to trips table');
    } catch (e) {
      print('[IMU_DEBUG][_saveDriveSession] ❌ Error saving drive session: $e');
      _showSnack('Warning: Failed to save drive session times');
    }
  }

  void _showSnack(String message) {
    print('[IMU_DEBUG][_showSnack] $message');
    final DateTime now = DateTime.now();
    if (_lastSnackAt != null && now.difference(_lastSnackAt!).inMilliseconds < _snackDebounceMs) {
      print('[IMU_DEBUG][_showSnack] Snack throttled');
      return;
    }
    _lastSnackAt = now;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    print('[IMU_DEBUG][dispose] Called');
    _cameraService.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('[IMU_DEBUG][build] Building widget');
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
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
        backgroundColor: const Color(0xFF01010D),
        appBar: AppBar(
          title: const Text("IMU + Camera Data Collector"),
          backgroundColor: const Color(0xFF0E0E1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout();
            } else {
              return _buildPortraitLayout();
            }
          },
        ),
      ), // Close Scaffold
    ); // Close PopScope
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
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
    return Container(
      child: Row(
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
      ),
    );
  }

  Widget _buildCameraPreview({double? height, bool isLandscape = false}) {
    if (_cameraService.isReady && _cameraService.controller != null) {
      // Use reciprocal aspect ratio for landscape mode
      final aspectRatio = isLandscape 
          ? _cameraService.controller!.value.aspectRatio 
          : 1 / _cameraService.controller!.value.aspectRatio;
      
      return Container(
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF765FD1), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF765FD1).withOpacity(0.3),
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
          color: const Color(0xFF0E0E1A),
          border: Border.all(color: const Color(0xFF765FD1), width: 2),
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
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF765FD1).withOpacity(0.3)),
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
              _buildStatCard('IMU Data', '${_imuDataCount - _uploadedImuCount}', '$_uploadedImuCount'),
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
                  (isCollecting && !isStopping) ? stopCollection : (!isCollecting ? startCollection : null),
              icon:
                  isStopping
                      ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                      : Icon(isCollecting ? Icons.stop : Icons.play_arrow),
              label: Text(isStopping ? 'Stopping...' : (isCollecting ? 'Stop Collection' : 'Start Collection')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCollecting ? const Color(0xFFF24E1E) : const Color(0xFF4CAF50),
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
                print('[IMU_DEBUG][UploadNowButton] Upload Now pressed');
                await _cameraService.uploadBatch();
                _showSnack('Upload triggered');
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_cameraService.pendingFramesCount == 0) ? Colors.grey : const Color(0xFF765FD1),
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
        color: isCollecting ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCollecting ? const Color(0xFF4CAF50) : Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCollecting ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isCollecting ? const Color(0xFF4CAF50) : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            isCollecting ? 'Data Collection Active' : 'Data Collection Stopped',
            style: TextStyle(
              color: isCollecting ? const Color(0xFF4CAF50) : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String processed, String uploaded) {
    // print('[IMU_DEBUG][_buildStatCard] $title: processed=$processed, uploaded=$uploaded');
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
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
