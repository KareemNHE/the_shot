//services/video_service.dart
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class VideoService {
  // Compress video to ~360p with H.264/AAC
  Future<File?> compressVideo(File videoFile, BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.mp4';

      // Compress using video_compress
      print('Compressing video: ${videoFile.path}');
      final compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality, // Approximates 360p
        deleteOrigin: false, // Keep original file
        frameRate: 24, // Match FFmpeg's 24 FPS
        includeAudio: true, // Ensure AAC audio
      );

      if (compressedVideo == null || compressedVideo.path == null) {
        print('Video compression failed: compressedVideo is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to compress video: Compression returned null')),
        );
        return null;
      }

      final compressedFile = File(compressedVideo.path!);
      // Move to desired output path
      final movedFile = await compressedFile.copy(outputPath);
      print('Video compression successful: $outputPath');
      return movedFile;
    } catch (e) {
      print('Error compressing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error compressing video: $e')),
      );
      return null;
    }
  }

  // Generate and upload video thumbnail
  Future<String?> generateAndUploadThumbnail(File videoFile, String userId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnailPath == null) {
        print('Failed to generate thumbnail');
        return null;
      }

      final thumbnailFile = File(thumbnailPath);
      final filename = '${DateTime.now().millisecondsSinceEpoch}_thumbnail.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('thumbnails/$userId/$filename');
      final uploadTask = await storageRef.putFile(thumbnailFile);
      final thumbnailUrl = await uploadTask.ref.getDownloadURL();

      print('Thumbnail uploaded successfully: $thumbnailUrl');
      return thumbnailUrl;
    } catch (e) {
      print('Error generating/uploading thumbnail: $e');
      return null;
    }
  }

  // Validate video duration (max 60 seconds) and resolution
  Future<Map<String, dynamic>> validateVideo(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      final duration = controller.value.duration;
      final size = controller.value.size;
      await controller.dispose();

      return {
        'isValidDuration': duration.inSeconds <= 60,
        'width': size.width.toInt(),
        'height': size.height.toInt(),
      };
    } catch (e) {
      print('Error validating video: $e');
      return {
        'isValidDuration': false,
        'width': 0,
        'height': 0,
      };
    }
  }
}