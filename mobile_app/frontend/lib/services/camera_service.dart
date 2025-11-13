import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A single, production-ready widget that:
// - Streams camera frames at low resolution
// - Throttles to ~3 fps
// - Converts frames to 224x224 grayscale and compresses to WebP (~70% quality)
// - Buffers to /cache and uploads every 10s to Supabase (storage + metadata)
// - Provides basic retry by keeping files in cache until upload succeeds
class CameraService extends StatefulWidget {
  const CameraService({super.key});

  @override
  State<CameraService> createState() => _CameraServiceState();
}

class _CameraServiceState extends State<CameraService> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isStreaming = false;

  // Throttle state
  int _lastProcessedMs = 0;
  static const int _throttleMs = 333; // ~3 fps

  // SnackBar throttle state
  DateTime? _lastSnackAt;
  static const int _snackDebounceMs = 2000; // min gap between snackbars

  // Cache/batching state
  late Directory _cacheDir;
  late Directory _framesDir;
  final List<_FrameRecord> _pendingFrames = <_FrameRecord>[]; // FIFO of cached frames
  Timer? _batchTimer;

  // Config (adjust via TODOs as needed)
  static const int _targetWidth = 224;
  static const int _targetHeight = 224;
  static const int _webpQuality = 70; // aim ~10-20KB
  // static const int _batchIntervalSeconds = 10;
  static const int _batchSize = 30; // ~10s * 3fps

  // Supabase config
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'vehicle_ride_img'; // TODO: set your bucket name
  final String _imageTable = 'image_data'; // TODO: set your table name
  final String _deviceId = 'dummy-device-id'; // TODO: inject real device id
  final String _currentImuBatchId = 'imu-batch-dummy'; // TODO: integrate with your IMU batch id source

  // UI counters
  int _processedCount = 0;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      await _prepareCacheDirs();
      await _initCamera();
      // _startBatchTimer();
    } catch (e, st) {
      debugPrint('Init error: $e\n$st');
      _showSnack('Init failed: $e');
    }
  }

  Future<void> _prepareCacheDirs() async {
    _cacheDir = await getTemporaryDirectory();
    _framesDir = Directory('${_cacheDir.path}/frames');
    if (!await _framesDir.exists()) {
      await _framesDir.create(recursive: true);
    }
    // On startup, load any leftover frames for retry.
    final entries = _framesDir.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
    for (final file in entries) {
      _pendingFrames.add(
        _FrameRecord(
          filePath: file.path,
          timestampMs: _extractTimestampFromFilename(file.path) ?? DateTime.now().millisecondsSinceEpoch,
          imuBatchId: _currentImuBatchId,
          deviceId: _deviceId,
        ),
      );
    }
    debugPrint('Pending frames restored: ${_pendingFrames.length}');
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    final CameraDescription cam = cameras.first;
    _controller = CameraController(
      cam,
      ResolutionPreset.high, // 640x480 target
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Prefer YUV for efficient luminance access (Android)
    );

    await _controller!.initialize();
    setState(() => _isReady = true);

    // Don't auto-start the image stream - wait for user to click start button
  }

  // void _startBatchTimer() {
  //   _batchTimer?.cancel();
  //   _batchTimer = Timer.periodic(const Duration(seconds: _batchIntervalSeconds), (_) {
  //     _uploadBatch();
  //   });
  // }

  void _onCameraImage(CameraImage cameraImage) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessedMs < _throttleMs) {
      return; // drop frame to throttle
    }
    _lastProcessedMs = now;

    try {
      final Uint8List webpBytes = await _processFrame(cameraImage);
      final String filePath = await _saveLocally(webpBytes, now);

      _pendingFrames.add(
        _FrameRecord(filePath: filePath, timestampMs: now, imuBatchId: _currentImuBatchId, deviceId: _deviceId),
      );

      _processedCount++;
      if (_processedCount % 10 == 0) {
        debugPrint('Processed frames: $_processedCount, pending: ${_pendingFrames.length}');
      }
    } catch (e, st) {
      debugPrint('Frame process error: $e\n$st');
      _showSnack('Frame process error: $e');
    }
  }

  // Convert CameraImage -> 224x224 grayscale -> WebP bytes (~70% quality)
  Future<Uint8List> _processFrame(CameraImage cameraImage) async {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    // Build a grayscale image using luminance data
    final img.Image gray = img.Image(width: width, height: height);

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      // Use Y plane (luminance)
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
      // Fallback for BGRA8888 or others: average RGB to grayscale from first plane
      final Plane p0 = cameraImage.planes[0];
      final int bytesPerRow = p0.bytesPerRow;
      final Uint8List bytes = p0.bytes;
      const int bpp = 4; // BGRA
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

    final img.Image resized = img.copyResize(
      gray,
      width: _targetWidth,
      height: _targetHeight,
      interpolation: img.Interpolation.average,
    );

    // Encode to PNG first; then compress to WebP via flutter_image_compress
    final Uint8List pngBytes = Uint8List.fromList(img.encodePng(resized));
    final Uint8List webpBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      quality: _webpQuality,
      format: CompressFormat.webp,
    );
    return webpBytes;
  }

  Future<String> _saveLocally(Uint8List bytes, int timestampMs) async {
    final String fileName = 'frame_${timestampMs}.webp';
    final String fullPath = '${_framesDir.path}/$fileName';
    final file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);
    return fullPath;
  }

  Future<void> _uploadBatch() async {
    if (_pendingFrames.isEmpty) return;

    final int count = _pendingFrames.length < _batchSize ? _pendingFrames.length : _batchSize;
    final List<_FrameRecord> batch = List<_FrameRecord>.from(_pendingFrames.take(count));
    if (batch.isEmpty) return;

    debugPrint('Uploading batch: ${batch.length} frames');
    try {
      // 1) Upload images to Supabase Storage
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      for (final _FrameRecord rec in batch) {
        final File f = File(rec.filePath);
        final String storagePath = _buildStoragePath(rec);
        await _supabase.storage.from(_bucketName).upload(storagePath, f);

        final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(storagePath);

        rows.add({
          // id: leave out to use DEFAULT gen (UUID) on DB side
          'timestamp': DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toUtc().toIso8601String(),
          'file_url': publicUrl,
          'vehicle_id': 8,
          // Add more fields as needed (e.g., device_id, imu_batch_id) if your schema supports it
          'device_id': rec.deviceId,
          'imu_batch_id': rec.imuBatchId,
        });
      }

      // 2) Insert metadata rows (single request)
      await _supabase.from(_imageTable).insert(rows);

      // 3) On success, remove from queue and delete files
      for (int i = 0; i < batch.length; i++) {
        final _FrameRecord rec = batch[i];
        try {
          _pendingFrames.remove(rec);
          final f = File(rec.filePath);
          if (await f.exists()) {
            await f.delete();
          }
          _uploadedCount++;
        } catch (e) {
          debugPrint('Cleanup error: $e');
        }
      }
      debugPrint('Batch upload complete. Uploaded so far: $_uploadedCount');
    } catch (e, st) {
      // Leave files in cache for retry on next tick
      debugPrint('Batch upload error: $e\n$st');
      _showSnack('Upload failed: $e');
    }
  }

  Future<void> _stopUploads() async {
    _batchTimer?.cancel();
    _showSnack('Uploads stopped');
  }

  Future<void> _clearCache() async {
    try {
      // Stop any ongoing uploads first
      _batchTimer?.cancel();

      // Clear pending frames list
      _pendingFrames.clear();

      // Delete all cached files
      if (await _framesDir.exists()) {
        final entries = _framesDir.listSync().whereType<File>().toList();
        for (final file in entries) {
          await file.delete();
        }
      }

      // Reset counters
      setState(() {
        _processedCount = 0;
        _uploadedCount = 0;
      });

      _showSnack('Cache cleared successfully');
      debugPrint('Cache cleared: deleted ${_framesDir.listSync().length} files');
    } catch (e, st) {
      debugPrint('Clear cache error: $e\n$st');
      _showSnack('Failed to clear cache: $e');
    }
  }

  String _buildStoragePath(_FrameRecord rec) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toUtc();
    final String dateDir = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final String name = 'frame_${rec.timestampMs}_${rec.deviceId}.webp';
    return '$dateDir/$name';
  }

  int? _extractTimestampFromFilename(String path) {
    final RegExp re = RegExp(r'frame_(\d+)');
    final match = re.firstMatch(path);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _showSnack(String message) {
    final DateTime now = DateTime.now();
    if (_lastSnackAt != null && now.difference(_lastSnackAt!).inMilliseconds < _snackDebounceMs) {
      return;
    }
    _lastSnackAt = now;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Image Logger')),
      body: Column(
        children: [
          AspectRatio(aspectRatio: 3 / 4, child: CameraPreview(_controller!)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Processed: $_processedCount'),
                Text('Queued: ${_pendingFrames.length}'),
                Text('Uploaded: $_uploadedCount'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _isStreaming
                          ? null
                          : () async {
                            try {
                              await _controller?.startImageStream(_onCameraImage);
                              setState(() => _isStreaming = true);
                            } catch (e) {
                              debugPrint('Start stream error: $e');
                              _showSnack('Start stream error: $e');
                            }
                          },
                  child: const Text('Start Stream'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      !_isStreaming
                          ? null
                          : () async {
                            try {
                              await _controller?.stopImageStream();
                              setState(() => _isStreaming = false);
                            } catch (e) {
                              debugPrint('Stop stream error: $e');
                              _showSnack('Stop stream error: $e');
                            }
                          },
                  child: const Text('Stop Stream'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _uploadBatch();
                  },
                  child: const Text('Upload Now'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _stopUploads();
                  },
                  child: const Text('Stop Upload'),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _clearCache();
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _batchTimer?.cancel();
    if (_isStreaming) {
      _controller?.stopImageStream();
    }
    _controller?.dispose();
    _clearCache();
    super.dispose();
  }
}

class _FrameRecord {
  final String filePath;
  final int timestampMs;
  final String imuBatchId;
  final String deviceId;
  _FrameRecord({required this.filePath, required this.timestampMs, required this.imuBatchId, required this.deviceId});
}
