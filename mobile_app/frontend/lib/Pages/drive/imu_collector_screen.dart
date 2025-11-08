// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/services/imu_service.dart';

class ImuCollector extends StatefulWidget {
  const ImuCollector({super.key});

  @override
  State<ImuCollector> createState() => _ImuCollectorState();
}

class _ImuCollectorState extends State<ImuCollector> {
  final ImuService _imuService = ImuService();
  final supabase = Supabase.instance.client;

  // Collection state
  bool isCollecting = false;
  bool isCameraReady = false;
  bool isStreaming = false;

  // Camera controller
  CameraController? _cameraController;

  // Data collection state
  int _imuDataCount = 0;
  int _imageDataCount = 0;
  int _uploadedImuCount = 0;
  int _uploadedImageCount = 0;

  // Camera processing state
  int _lastProcessedMs = 0;
  static const int _throttleMs = 333; // ~3 fps
  late Directory _cacheDir;
  late Directory _framesDir;
  final List<_FrameRecord> _pendingFrames = <_FrameRecord>[];
  Timer? _batchTimer;

  // Camera config
  static const int _targetWidth = 224;
  static const int _targetHeight = 224;
  static const int _webpQuality = 70;
  static const int _batchIntervalSeconds = 10;
  static const int _batchSize = 30;

  // Supabase config
  final String _bucketName = 'vehicle_ride_img';
  final String _imageTable = 'image_data';
  final String _deviceId = 'mobile-device-${DateTime.now().millisecondsSinceEpoch}';
  final String _currentImuBatchId = 'imu-batch-${DateTime.now().millisecondsSinceEpoch}';

  // SnackBar throttle
  DateTime? _lastSnackAt;
  static const int _snackDebounceMs = 2000;

  @override
  void initState() {
    super.initState();
    print('[IMU_DEBUG][initState] Called');
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      print('[IMU_DEBUG][_initAll] 🚀 Initializing IMU Collector...');
      await _prepareCacheDirs();
      await _initCamera();
      await _initLocation();
      print('[IMU_DEBUG][_initAll] ✅ IMU Collector initialized successfully');
    } catch (e, st) {
      print('[IMU_DEBUG][_initAll] ❌ Init error: $e\n$st');
      _showSnack('Initialization failed: $e');
    }
  }

  Future<void> _prepareCacheDirs() async {
    print('[IMU_DEBUG][_prepareCacheDirs] Preparing cache directories...');
    _cacheDir = await getTemporaryDirectory();
    _framesDir = Directory('${_cacheDir.path}/frames');
    if (!await _framesDir.exists()) {
      await _framesDir.create(recursive: true);
    }
    print('[IMU_DEBUG][_prepareCacheDirs] 📁 Cache directories prepared');
  }

  Future<void> _initCamera() async {
    print('[IMU_DEBUG][_initCamera] Initializing camera...');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      final CameraDescription cam = cameras.first;
      _cameraController = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      setState(() => isCameraReady = true);
      print('[IMU_DEBUG][_initCamera] 📷 Camera initialized successfully');
    } catch (e) {
      print('[IMU_DEBUG][_initCamera] ❌ Camera init error: $e');
      _showSnack('Camera initialization failed: $e');
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
      _showSnack('Location initialization failed: $e');
    }
  }

  void startCollection() async {
    print('[IMU_DEBUG][startCollection] Called');
    if (isCollecting) return;

    try {
      print('[IMU_DEBUG][startCollection] 🔄 Starting data collection...');

      // Start IMU collection
      await _imuService.start(
        context: context,
        manageLocationStream: true,
        useUserAccelerometer: false,
        onDataCountUpdate: (processed, uploaded) {
          print('[IMU_DEBUG][startCollection] onDataCountUpdate: processed=$processed, uploaded=$uploaded');
          setState(() {
            _imuDataCount = processed;
            _uploadedImuCount = uploaded;
          });
        },
      );

      // Start camera streaming
      if (_cameraController != null && !isStreaming) {
        await _cameraController!.startImageStream(_onCameraImage);
        setState(() => isStreaming = true);
        print('[IMU_DEBUG][startCollection] 📷 Camera streaming started');
      }

      // Start batch upload timer
      _startBatchTimer();

      setState(() => isCollecting = true);
      print('[IMU_DEBUG][startCollection] ✅ Data collection started successfully');
      _showSnack('Data collection started!');
    } catch (e) {
      print('[IMU_DEBUG][startCollection] ❌ Start collection error: $e');
      _showSnack('Failed to start collection: $e');
    }
  }

  void stopCollection() async {
    print('[IMU_DEBUG][stopCollection] Called');
    try {
      print('[IMU_DEBUG][stopCollection] ⏹️ Stopping data collection...');

      // Stop IMU collection
      _imuService.stop(context);

      // Stop camera streaming
      if (_cameraController != null && isStreaming) {
        await _cameraController!.stopImageStream();
        setState(() => isStreaming = false);
        print('[IMU_DEBUG][stopCollection] 📷 Camera streaming stopped');
      }

      // Stop batch timer
      _batchTimer?.cancel();

      // Upload any remaining data
      await _uploadBatch();

      setState(() => isCollecting = false);
      print('[IMU_DEBUG][stopCollection] ✅ Data collection stopped successfully');
      _showSnack('Data collection stopped!');
    } catch (e) {
      print('[IMU_DEBUG][stopCollection] ❌ Stop collection error: $e');
      _showSnack('Error stopping collection: $e');
    }
  }

  void _startBatchTimer() {
    print('[IMU_DEBUG][_startBatchTimer] Starting batch timer...');
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: _batchIntervalSeconds), (_) {
      print('[IMU_DEBUG][_startBatchTimer] Timer tick - calling _uploadBatch');
      _uploadBatch();
    });
    print('[IMU_DEBUG][_startBatchTimer] ⏰ Batch upload timer started (every $_batchIntervalSeconds seconds)');
  }

  void _onCameraImage(CameraImage cameraImage) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessedMs < _throttleMs) {
      print('[IMU_DEBUG][_onCameraImage] Frame dropped due to throttle');
      return; // drop frame to throttle
    }
    _lastProcessedMs = now;

    try {
      print('[IMU_DEBUG][_onCameraImage] Processing frame at $now');
      final Uint8List webpBytes = await _processFrame(cameraImage);
      final String filePath = await _saveLocally(webpBytes, now);

      _pendingFrames.add(
        _FrameRecord(filePath: filePath, timestampMs: now, imuBatchId: _currentImuBatchId, deviceId: _deviceId),
      );

      setState(() => _imageDataCount++);

      if (_imageDataCount % 10 == 0) {
        print('[IMU_DEBUG][_onCameraImage] 📸 Processed images: $_imageDataCount, pending: ${_pendingFrames.length}');
      }
    } catch (e, st) {
      print('[IMU_DEBUG][_onCameraImage] ❌ Frame process error: $e\n$st');
      _showSnack('Frame processing error: $e');
    }
  }

  Future<Uint8List> _processFrame(CameraImage cameraImage) async {
    print('[IMU_DEBUG][_processFrame] Called');
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final img.Image gray = img.Image(width: width, height: height);

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      final Plane yPlane = cameraImage.planes[0];
      final int bytesPerRow = yPlane.bytesPerRow;
      final Uint8List yBytes = yPlane.bytes;
      for (int y = 0; y < height; y++) {
        final int rowStart = y * bytesPerRow;
        for (int x = 0; x < width; x++) {
          final int luminance = yBytes[rowStart + x];
          gray.setPixelRgba(x, y, luminance, luminance, luminance, 255);
        }
      }
    } else {
      final Plane p0 = cameraImage.planes[0];
      final int bytesPerRow = p0.bytesPerRow;
      final Uint8List bytes = p0.bytes;
      const int bpp = 4;
      for (int y = 0; y < height; y++) {
        final int rowStart = y * bytesPerRow;
        for (int x = 0; x < width; x++) {
          final int pixelIndex = rowStart + x * bpp;
          final int b = bytes[pixelIndex + 0];
          final int g = bytes[pixelIndex + 1];
          final int r = bytes[pixelIndex + 2];
          final int luminance = ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
          gray.setPixelRgba(x, y, luminance, luminance, luminance, 255);
        }
      }
    }

    // Rotate to match preview orientation
    int rotationDegrees = 0;
    final orientation = _cameraController?.value.deviceOrientation;
    if (orientation != null) {
      switch (orientation) {
        case DeviceOrientation.portraitUp:
          rotationDegrees = 90; // buffers are landscape by default
          break;
        case DeviceOrientation.landscapeLeft:
          rotationDegrees = 0;
          break;
        case DeviceOrientation.portraitDown:
          rotationDegrees = 270;
          break;
        case DeviceOrientation.landscapeRight:
          rotationDegrees = 180;
          break;
      }
    }
    img.Image oriented = rotationDegrees == 0 ? gray : img.copyRotate(gray, angle: rotationDegrees);

    // Mirror front camera to match preview
    if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
      oriented = img.flipHorizontal(oriented);
    }

    // Preserve aspect ratio: scale longest side to target, keep the other side proportional
    final int srcW = oriented.width;
    final int srcH = oriented.height;
    final int maxSide = _targetWidth; // use target as the max side
    final double scale = srcW >= srcH ? maxSide / srcW : maxSide / srcH;
    final int outW = (srcW * scale).round();
    final int outH = (srcH * scale).round();
    final img.Image resized = img.copyResize(
      oriented,
      width: outW,
      height: outH,
      interpolation: img.Interpolation.average,
    );

    final Uint8List pngBytes = Uint8List.fromList(img.encodePng(resized));
    final Uint8List webpBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      quality: _webpQuality,
      format: CompressFormat.webp,
    );
    print('[IMU_DEBUG][_processFrame] Frame processed and compressed');
    return webpBytes;
  }

  Future<String> _saveLocally(Uint8List bytes, int timestampMs) async {
    print('[IMU_DEBUG][_saveLocally] Saving frame at $timestampMs');
    final String fileName = 'frame_${timestampMs}.webp';
    final String fullPath = '${_framesDir.path}/$fileName';
    final file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);
    print('[IMU_DEBUG][_saveLocally] Saved to $fullPath');
    return fullPath;
  }

  Future<void> _uploadBatch() async {
    print('[IMU_DEBUG][_uploadBatch] Called');
    if (_pendingFrames.isEmpty) {
      print('[IMU_DEBUG][_uploadBatch] No pending frames to upload');
      return;
    }

    final int count = _pendingFrames.length < _batchSize ? _pendingFrames.length : _batchSize;
    final List<_FrameRecord> batch = List<_FrameRecord>.from(_pendingFrames.take(count));
    if (batch.isEmpty) {
      print('[IMU_DEBUG][_uploadBatch] Batch is empty after take()');
      return;
    }

    print('[IMU_DEBUG][_uploadBatch] 📤 Uploading batch: ${batch.length} frames');
    try {
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      for (final _FrameRecord rec in batch) {
        print('[IMU_DEBUG][_uploadBatch] Uploading file: ${rec.filePath}');
        final File f = File(rec.filePath);
        final String storagePath = _buildStoragePath(rec);
        await supabase.storage.from(_bucketName).upload(storagePath, f);

        final String publicUrl = supabase.storage.from(_bucketName).getPublicUrl(storagePath);

        rows.add({
          'timestamp': DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toUtc().toIso8601String(),
          'file_url': publicUrl,
          'vehicle_id': context.read<VehicleProvider>().vehicleId,
          'device_id': rec.deviceId,
          'imu_batch_id': rec.imuBatchId,
        });
      }

      print('[IMU_DEBUG][_uploadBatch] Inserting rows to $_imageTable');
      await supabase.from(_imageTable).insert(rows);

      for (int i = 0; i < batch.length; i++) {
        final _FrameRecord rec = batch[i];
        try {
          _pendingFrames.remove(rec);
          final f = File(rec.filePath);
          if (await f.exists()) {
            await f.delete();
          }
          setState(() => _uploadedImageCount++);
          print('[IMU_DEBUG][_uploadBatch] Cleaned up file: ${rec.filePath}');
        } catch (e) {
          print('[IMU_DEBUG][_uploadBatch] ❌ Cleanup error: $e');
        }
      }
      print('[IMU_DEBUG][_uploadBatch] ✅ Batch upload complete. Uploaded images: $_uploadedImageCount');
      _showSnack('Uploaded ${batch.length} images');
    } catch (e, st) {
      print('[IMU_DEBUG][_uploadBatch] ❌ Batch upload error: $e\n$st');
      _showSnack('Upload failed: $e');
    }
  }

  String _buildStoragePath(_FrameRecord rec) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toUtc();
    final String dateDir = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final String name = 'frame_${rec.timestampMs}_${rec.deviceId}.webp';
    final String path = '$dateDir/$name';
    print('[IMU_DEBUG][_buildStoragePath] Storage path: $path');
    return path;
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
    _batchTimer?.cancel();
    if (isStreaming) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _imuService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[IMU_DEBUG][build] Building widget');
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
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
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
          if (isCameraReady && _cameraController != null)
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
                  aspectRatio: 1 / _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
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
                    _buildStatCard('Images', '${_imageDataCount - _uploadedImageCount}', '$_uploadedImageCount'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pending Images: ${_pendingFrames.length}',
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
                    onPressed: isCollecting ? stopCollection : startCollection,
                    icon: Icon(isCollecting ? Icons.stop : Icons.play_arrow),
                    label: Text(isCollecting ? 'Stop Collection' : 'Start Collection'),
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
                      await _uploadBatch();
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_pendingFrames.isEmpty) ? Colors.grey : Colors.blue,
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
    print('[IMU_DEBUG][_buildStatCard] $title: processed=$processed, uploaded=$uploaded');
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

class _FrameRecord {
  final String filePath;
  final int timestampMs;
  final String imuBatchId;
  final String deviceId;

  _FrameRecord({required this.filePath, required this.timestampMs, required this.imuBatchId, required this.deviceId});
}
