// viewmodels/captured_photo_viewmodel.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class CapturedPhotoViewModel extends ChangeNotifier {
  Future<void> savePhoto(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await File('${directory.path}/$timestamp.jpg').create();
      await file.writeAsBytes(await File(imagePath).readAsBytes());
      print('Photo saved: ${file.path}');
    } catch (e) {
      print('Error saving photo: $e');
    }
  }

  Future<String?> uploadPhoto(String imagePath, BuildContext context) async {

    print('Captured photo path: $imagePath');

    if (imagePath.isEmpty || !File(imagePath).existsSync()) {
      print('Invalid file path: $imagePath');
      return null;
    }

    try {
      // Check if the path is valid
      if (imagePath.isEmpty || !File(imagePath).existsSync()) {
        print('Invalid file path: $imagePath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid photo path. Please try again.')),
        );
        return null;
      }

      final storage = FirebaseStorage.instance;
      final ref = storage
          .ref()
          .child('posts')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file
      final uploadTask = ref.putFile(File(imagePath));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo. Please try again.')),
      );
      return null;
    }
  }
}
