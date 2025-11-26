import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A service that:
// - Captures full RGB images using takePicture()
// - Throttles to ~2 fps (configurable)
// - Buffers to /cache and uploads every 10s to Supabase (storage + metadata)
// - Provides basic retry by keeping files in cache until upload succeeds
class CameraService {
  CameraController? _controller;
  bool _isReady = false;
  bool _isStreaming = false;

  // Throttle state
  Timer? _captureTimer;
  static const Duration _captureInterval = Duration(milliseconds: 500); // ~2 fps

  // Cache/batching state
  late Directory _cacheDir;
  late Directory _framesDir;
  final List<_FrameRecord> _pendingFrames = <_FrameRecord>[]; // FIFO of cached frames
  Timer? _batchTimer;

  // Config
  static const int _batchIntervalSeconds = 10;
  static const int _batchSize = 30;

  // Supabase config
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'vehicle_ride_img';
  final String _imageTable = 'image_data';

  // Current session config
  String? _vehicleId;
  String? _deviceId;
  String? _imuBatchId;

  // Stats
  int _processedCount = 0;
  int _uploadedCount = 0;
  VoidCallback? onStatsUpdated;

  // Public getters
  bool get isReady => _isReady;
  bool get isStreaming => _isStreaming;
  CameraController? get controller => _controller;
  int get pendingFramesCount => _pendingFrames.length;
  int get processedCount => _processedCount;
  int get uploadedCount => _uploadedCount;

  Future<void> initialize() async {
    try {
      await _prepareCacheDirs();
      await _initCamera();
    } catch (e, st) {
      debugPrint('Init error: $e\n$st');
      rethrow;
    }
  }

  Future<void> _prepareCacheDirs() async {
    _cacheDir = await getTemporaryDirectory();
    _framesDir = Directory('${_cacheDir.path}/frames_rgb');
    if (!await _framesDir.exists()) {
      await _framesDir.create(recursive: true);
    }
    // On startup, load any leftover frames for retry.
    final entries = _framesDir.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
    for (final file in entries) {
      final timestamp = _extractTimestampFromFilename(file.path) ?? DateTime.now().millisecondsSinceEpoch;
      final deviceId = _extractDeviceIdFromFilename(file.path) ?? 'unknown_device';

      _pendingFrames.add(
        _FrameRecord(
          filePath: file.path,
          timestampMs: timestamp,
          imuBatchId: 'restored_batch',
          deviceId: deviceId,
          vehicleId: 'unknown_vehicle',
        ),
      );
    }
    debugPrint('Pending RGB frames restored: ${_pendingFrames.length}');
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    final CameraDescription cam = cameras.first;
    _controller = CameraController(
      cam,
      ResolutionPreset.medium, // Use medium to avoid massive files if high isn't needed
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg, // We want JPEGs from takePicture
    );

    await _controller!.initialize();
    _isReady = true;
  }

  Future<void> startStreaming({required String vehicleId, required String deviceId, required String imuBatchId}) async {
    if (!_isReady || _controller == null) {
      debugPrint('Camera not ready');
      return;
    }
    if (_isStreaming) return;

    _vehicleId = vehicleId;
    _deviceId = deviceId;
    _imuBatchId = imuBatchId;

    _processedCount = 0;
    _uploadedCount = 0;
    onStatsUpdated?.call();

    try {
      _startCaptureTimer();
      _startBatchTimer();
      _isStreaming = true;
      print('📱 Started RGB camera capture (auto-upload every ${_batchIntervalSeconds}s)');
    } catch (e) {
      print('Start stream error: $e');
      rethrow;
    }
  }

  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    try {
      _captureTimer?.cancel();
      _batchTimer?.cancel();
      _isStreaming = false;
      print('⏹️ Stopped RGB camera capture');

      // Try one last upload
      await uploadBatch();
    } catch (e) {
      print('Stop stream error: $e');
      rethrow;
    }
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(_captureInterval, (_) async {
      await _captureFrame();
    });
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: _batchIntervalSeconds), (_) async {
      await uploadBatch();
    });
  }

  Future<void> _captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();
      final int now = DateTime.now().millisecondsSinceEpoch;

      final int originalSize = await file.length();

      // Read bytes
      final Uint8List bytes = await file.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('Failed to decode image');
        return;
      }

      // Resize to 512x512 (maintain aspect ratio if needed, but here forcing or fitting)
      // Let's use copyResize which handles aspect ratio if we only provide width or height,
      // or both to force. Let's fit to 512 width.
      img.Image resized = img.copyResize(image, width: 512);

      // Convert to grayscale
      img.Image grayscale = img.grayscale(resized);

      // Encode to JPG with reduced quality
      final Uint8List processedBytes = img.encodeJpg(grayscale, quality: 70);

      debugPrint(
        'Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB, Processed size: ${(processedBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      // Save processed file
      final String newPath = await _saveLocally(processedBytes, now);

      _pendingFrames.add(
        _FrameRecord(
          filePath: newPath,
          timestampMs: now,
          imuBatchId: _imuBatchId ?? 'unknown_batch',
          deviceId: _deviceId ?? 'unknown_device',
          vehicleId: _vehicleId ?? 'unknown_vehicle',
        ),
      );

      _processedCount++;
      onStatsUpdated?.call();

      if (_pendingFrames.length >= _batchSize) {
        debugPrint('Batch limit reached (${_pendingFrames.length}), uploading now...');
        uploadBatch();
      }
    } catch (e) {
      debugPrint('Frame capture error: $e');
    }
  }

  Future<String> _saveLocally(Uint8List bytes, int timestampMs) async {
    final devId = _deviceId ?? 'unknown';
    final String fileName = 'frame_${timestampMs}_$devId.jpg';
    final String fullPath = '${_framesDir.path}/$fileName';
    final File file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);
    return fullPath;
  }

  Future<void> uploadBatch() async {
    if (_pendingFrames.isEmpty) return;

    final List<_FrameRecord> batch = List<_FrameRecord>.from(_pendingFrames);
    if (batch.isEmpty) return;

    debugPrint('Uploading batch: ${batch.length} frames');

    try {
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      final List<_FrameRecord> recordsForInsert = <_FrameRecord>[];

      for (final _FrameRecord rec in batch) {
        final File f = File(rec.filePath);
        if (!f.existsSync()) {
          _pendingFrames.remove(rec);
          continue;
        }

        int? finalVehicleId = int.tryParse(rec.vehicleId);
        if (finalVehicleId == null && _vehicleId != null) {
          finalVehicleId = int.tryParse(_vehicleId!);
        }

        if (finalVehicleId == null) {
          _pendingFrames.remove(rec);
          await f.delete().catchError((_) => f);
          continue;
        }

        final String storagePath = _buildStoragePath(rec);

        await _supabase.storage.from(_bucketName).upload(storagePath, f, fileOptions: const FileOptions(upsert: true));
        final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(storagePath);

        rows.add({
          'timestamp': DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toLocal().toIso8601String(),
          'file_url': publicUrl,
          'vehicle_id': finalVehicleId,
          // 'device_id': rec.deviceId, // Removed from schema
          'imu_batch_id': rec.imuBatchId,
        });
        recordsForInsert.add(rec);
      }

      if (rows.isEmpty) return;

      try {
        await _supabase.from(_imageTable).insert(rows);

        for (final rec in recordsForInsert) {
          _pendingFrames.remove(rec);
          final f = File(rec.filePath);
          if (await f.exists()) await f.delete();
          _uploadedCount++;
        }
        onStatsUpdated?.call();
        debugPrint('Batch upload complete: ${rows.length} records.');
      } catch (insertError) {
        debugPrint('Bulk insert failed ($insertError), falling back to individual inserts...');
        for (int i = 0; i < rows.length; i++) {
          final row = rows[i];
          final rec = recordsForInsert[i];
          try {
            await _supabase.from(_imageTable).insert(row);
            _pendingFrames.remove(rec);
            final f = File(rec.filePath);
            if (await f.exists()) await f.delete();
            _uploadedCount++;
          } catch (singleErr) {
            if (singleErr is PostgrestException && singleErr.code == '23505') {
              _pendingFrames.remove(rec);
              final f = File(rec.filePath);
              if (await f.exists()) await f.delete();
            }
          }
        }
        onStatsUpdated?.call();
      }
    } catch (e, st) {
      debugPrint('Batch upload error: $e\n$st');
    }
  }

  Future<void> clearCache() async {
    try {
      _captureTimer?.cancel();
      _batchTimer?.cancel();
      _pendingFrames.clear();
      if (await _framesDir.exists()) {
        final entries = _framesDir.listSync().whereType<File>().toList();
        for (final file in entries) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }

  String _buildStoragePath(_FrameRecord rec) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toUtc();
    final String dateDir = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final String name = 'frame_${rec.timestampMs}_${rec.deviceId}.jpg';
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

  String? _extractDeviceIdFromFilename(String path) {
    final RegExp re = RegExp(r'frame_\d+_(.+)\.jpg');
    final match = re.firstMatch(path);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  void dispose() {
    _captureTimer?.cancel();
    _batchTimer?.cancel();
    _controller?.dispose();
  }
}

class _FrameRecord {
  final String filePath;
  final int timestampMs;
  final String imuBatchId;
  final String deviceId;
  final String vehicleId;
  _FrameRecord({
    required this.filePath,
    required this.timestampMs,
    required this.imuBatchId,
    required this.deviceId,
    required this.vehicleId,
  });
}
