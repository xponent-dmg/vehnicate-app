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

  // Collection state
  bool isCollecting = false;
  bool isStopping = false;

  // Data collection state
  int _imuDataCount = 0;
  int _uploadedImuCount = 0;

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

      // Stop Sensor collection and Camera streaming in parallel
      await Future.wait([_sensorService.stop(context), _cameraService.stopStreaming()]);

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
        appBar: AppBar(
          title: const Text("IMU + Camera Data Collector"),
          backgroundColor: Colors.deepPurple[600],
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Camera Preview
            if (_cameraService.isReady && _cameraService.controller != null)
              Container(
                height: 400,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraService.controller!.value.aspectRatio,
                    child: CameraPreview(_cameraService.controller!),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Camera not ready', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            // Statistics Display
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple[200]!),
              ),
              child: Column(
                children: [
                  const Text('Data Collection Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Control Buttons
            Padding(
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
                        backgroundColor: isCollecting ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        print('[IMU_DEBUG][UploadNowButton] Upload Now pressed');
                        await _cameraService.uploadBatch();
                        CustomSnackBar.showSuccess(context, 'Upload triggered');
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_cameraService.pendingFramesCount == 0) ? Colors.grey : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Status Indicator
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCollecting ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCollecting ? Colors.green : Colors.grey, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCollecting ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isCollecting ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCollecting ? 'Data Collection Active' : 'Data Collection Stopped',
                    style: TextStyle(
                      color: isCollecting ? Colors.green[800] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Close Scaffold
    ); // Close PopScope
  }

  Widget _buildStatCard(String title, String processed, String uploaded) {
    // print('[IMU_DEBUG][_buildStatCard] $title: processed=$processed, uploaded=$uploaded');
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(processed, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Uploaded: $uploaded', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
