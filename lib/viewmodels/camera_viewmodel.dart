// viewmodels/camera_viewmodel.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraViewModel extends ChangeNotifier {
  late CameraController _controller;
  bool _isCameraInitialized = false;

  CameraController get controller => _controller;
  bool get isCameraInitialized => _isCameraInitialized;

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;
        _controller = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );

        await _requestCameraPermission();
        await _controller.initialize();
        _isCameraInitialized = true;
        notifyListeners();
      } else {
        print('No camera available');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      print('Camera permission denied');
    }
  }

  Future<String?> capturePhoto() async {
    if (!_controller.value.isInitialized) {
      print('Camera not initialized');
      return null;
    }

    final image = await _controller.takePicture();
    return image.path;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
