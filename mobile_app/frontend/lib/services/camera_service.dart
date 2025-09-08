import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraService extends StatefulWidget {
  const CameraService({super.key});

  @override
  State<CameraService> createState() => _CameraServiceState();
}

class _CameraServiceState extends State<CameraService> {
  CameraController? _cameraController;
  Future<void>? _initializeCameraController;

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCam = cameras.first;
    _cameraController = CameraController(
      firstCam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeCameraController = _cameraController?.initialize();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body:
          (_cameraController == null)
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder(
                future: _initializeCameraController,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_cameraController!);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
    );
  }
}
