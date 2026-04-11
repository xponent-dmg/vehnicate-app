import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnicate_frontend/core/constants/app_config.dart';
import 'package:vehnicate_frontend/utils/app_logger.dart';

// A service that:
// - Captures full RGB images using takePicture()
// - Throttles to ~2 fps (configurable)
// - Buffers to /cache and uploads every 10s to Supabase (storage + metadata)
// - Provides basic retry by keeping files in cache until upload succeeds
class CameraServiceRGB {
  CameraController? _controller;
  bool _isReady = false;
  bool _isStreaming = false;

  // Throttle state
  Timer? _captureTimer;
  static const Duration _captureInterval = Duration(
    milliseconds: 500,
  ); // ~2 fps

  // Cache/batching state
  late Directory _cacheDir;
  late Directory _framesDir;
  final List<_FrameRecord> _pendingFrames =
      <_FrameRecord>[]; // FIFO of cached frames
  Timer? _batchTimer;

  // Config
  static const int _batchSize = 10;

  // Supabase config
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = AppConfig.bucketVehicleImages;
  final String _imageTable = AppConfig.tableImageData;

  // Current session config
  String? _vehicleId;
  String? _deviceId;
  String? _imuBatchId;

  // Stats
  int _processedCount = 0;
  int _uploadedCount = 0;
  bool _isUploading = false;
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
      AppLogger.info('CameraServiceRGB initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize CameraServiceRGB', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Camera initialization failed',
      );
      rethrow;
    }
  }

  Future<void> _prepareCacheDirs() async {
    try {
      _cacheDir = await getTemporaryDirectory();
      _framesDir = Directory('${_cacheDir.path}/frames_rgb');
      if (!await _framesDir.exists()) {
        await _framesDir.create(recursive: true);
      }
      // On startup, load any leftover frames for retry.
      final entries =
          _framesDir.listSync().whereType<File>().toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in entries) {
        final timestamp =
            _extractTimestampFromFilename(file.path) ??
            DateTime.now().toLocal().millisecondsSinceEpoch;
        final deviceId =
            _extractDeviceIdFromFilename(file.path) ?? 'unknown_device';

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
    } catch (e, stack) {
      AppLogger.warning('Error preparing cache directories', e, stack);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    final CameraDescription cam = cameras.first;
    _controller = CameraController(
      cam,
      ResolutionPreset
          .medium, // Use medium to avoid massive files if high isn't needed
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg, // We want JPEGs from takePicture
    );

    await _controller!.initialize();
    _isReady = true;
  }

  Future<void> startStreaming({
    required String vehicleId,
    required String deviceId,
    required String imuBatchId,
  }) async {
    if (!_isReady || _controller == null) {
      AppLogger.warning('Attempted to start streaming but camera is not ready');
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
      _isStreaming = true;
      AppLogger.info('Started camera streaming for vehicle $vehicleId');
    } catch (e, stack) {
      AppLogger.error('Error starting camera streaming', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to start camera streaming',
      );
      rethrow;
    }
  }

  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    try {
      _captureTimer?.cancel();
      _batchTimer?.cancel();
      _isStreaming = false;

      // Wait for any ongoing upload to finish before triggering the final one
      while (_isUploading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Try one last upload
      await uploadBatch();
      AppLogger.info('Stopped camera streaming');
    } catch (e, stack) {
      AppLogger.error('Error stopping camera streaming', e, stack);
      rethrow;
    }
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(_captureInterval, (_) async {
      await _captureFrame();
    });
  }

  Future<void> _captureFrame() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();

      // Capture values to pass to isolate
      final String rawPath = file.path;
      final String framesDirPath = _framesDir.path;
      final String deviceId = _deviceId ?? 'unknown';
      final RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;

      if (rootIsolateToken == null) {
        return;
      }

      final String? newPath = await Isolate.run(() async {
        // Initialize background isolate
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        final int now = DateTime.now().toLocal().millisecondsSinceEpoch;

        // 1. Compress and resize using flutter_image_compress (Native, fast)
        final Uint8List? compressedBytes =
            await FlutterImageCompress.compressWithFile(
              rawPath,
              minWidth: 512,
              minHeight: 512,
              quality: 70,
              format: CompressFormat.jpeg,
            );

        if (compressedBytes == null) {
          return null;
        }

        // 2. Save locally
        final String fileName = 'frame_${now}_$deviceId.jpg';
        final String fullPath = '$framesDirPath/$fileName';
        final File newFile = File(fullPath);
        await newFile.writeAsBytes(compressedBytes, flush: true);

        return fullPath;
      });

      if (newPath == null) return;

      final int timestamp =
          _extractTimestampFromFilename(newPath) ??
          DateTime.now().toLocal().millisecondsSinceEpoch;

      _pendingFrames.add(
        _FrameRecord(
          filePath: newPath,
          timestampMs: timestamp,
          imuBatchId: _imuBatchId ?? 'unknown_batch',
          deviceId: _deviceId ?? 'unknown_device',
          vehicleId: _vehicleId ?? 'unknown_vehicle',
        ),
      );

      _processedCount++;
      onStatsUpdated?.call();

      if (_pendingFrames.length >= _batchSize) {
        uploadBatch();
      }
    } catch (e, stack) {
      AppLogger.error('Error capturing camera frame', e, stack);
    }
  }

  Future<void> uploadBatch() async {
    if (_pendingFrames.isEmpty) return;
    if (_isUploading) return;

    _isUploading = true;

    final List<_FrameRecord> batch = List<_FrameRecord>.from(_pendingFrames);
    if (batch.isEmpty) {
      _isUploading = false;
      return;
    }

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

        await _supabase.storage
            .from(_bucketName)
            .upload(
              storagePath,
              f,
              fileOptions: const FileOptions(upsert: true),
            );
        final String publicUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl(storagePath);

        rows.add({
          'timestamp':
              DateTime.fromMillisecondsSinceEpoch(
                rec.timestampMs,
              ).toLocal().toIso8601String(),
          'file_url': publicUrl,
          'vehicle_id': finalVehicleId,
          'imu_batch_id': rec.imuBatchId,
        });
        recordsForInsert.add(rec);
      }

      if (rows.isEmpty) {
        _isUploading = false;
        return;
      }

      try {
        await _supabase.from(_imageTable).insert(rows);

        for (final rec in recordsForInsert) {
          _pendingFrames.remove(rec);
          final f = File(rec.filePath);
          if (await f.exists()) await f.delete();
          _uploadedCount++;
        }
        onStatsUpdated?.call();
      } catch (insertError) {
        AppLogger.warning(
          'Batch insert failed, attempting single inserts',
          insertError,
        );
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
            if (singleErr is PostgrestException &&
                (singleErr.code == '23505')) {
              _pendingFrames.remove(rec);
              final f = File(rec.filePath);
              if (await f.exists()) await f.delete();
            } else {
              AppLogger.error('Failed to insert single row', singleErr);
            }
          }
        }
        onStatsUpdated?.call();
      }
    } catch (e, stack) {
      AppLogger.error('Error during batch upload', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Camera batch upload failed',
      );
    } finally {
      _isUploading = false;
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
      AppLogger.info('Camera cache cleared');
    } catch (e, stack) {
      AppLogger.error('Error clearing camera cache', e, stack);
    }
  }

  String _buildStoragePath(_FrameRecord rec) {
    final DateTime dt =
        DateTime.fromMillisecondsSinceEpoch(rec.timestampMs).toLocal();
    final String dateDir =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
