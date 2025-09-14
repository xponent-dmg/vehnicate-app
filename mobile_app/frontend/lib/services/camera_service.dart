import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'dart:io' show Platform;

class CameraService extends StatefulWidget {
  const CameraService({super.key});

  @override
  State<CameraService> createState() => _CameraServiceState();
}

class _CameraServiceState extends State<CameraService> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras!.first, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    setState(() => _isReady = true);
  }

  Future<void> _takePicture() async {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;

    final XFile file = await _controller!.takePicture();
    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putImage(file.path);
      print("Saved to gallery: ${file.path}");
    } else {
      print("Saved image (unsupported gallery platform): ${file.path}");
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Gallery")));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Capture & Save')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AspectRatio(aspectRatio: 1 / _controller!.value.aspectRatio, child: CameraPreview(_controller!)),
          ElevatedButton(onPressed: _takePicture, child: const Text("📸 Take Photo")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
