// views/camera_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/camera_viewmodel.dart';
import 'package:the_shot2/views/captured_photo_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize camera using the Provider
    Future.microtask(() =>
        Provider.of<CameraViewModel>(context, listen: false).initializeCamera());
  }

  Future<void> _capturePhoto() async {
    final cameraViewModel =
    Provider.of<CameraViewModel>(context, listen: false);
    final imagePath = await cameraViewModel.capturePhoto();
    if (imagePath != null) {
      print('Captured photo path: $imagePath');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CapturedPhotoScreen(imagePath: imagePath),
        ),
      );
    } else {
      print('Error capturing photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraViewModel = Provider.of<CameraViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Screen'),
      ),
      body: cameraViewModel.isCameraInitialized
          ? CameraPreview(cameraViewModel.controller)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.camera_alt,
          color: Color(0xFFCB7CCB),
        ),
        onPressed: _capturePhoto,
      ),
    );
  }
}
