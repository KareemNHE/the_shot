//viewmodels/create_post_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mime/mime.dart';
import '../services/notification_service.dart';
import '../services/video_service.dart';
import 'home_viewmodel.dart';

class CreatePostViewModel extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final VideoService _videoService = VideoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CreatePostViewModel() {
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Post Uploaded',
      'Your post has been successfully uploaded.',
      platformChannelSpecifics,
    );
  }

  Future<void> uploadImagePost({
    required File imageFile,
    required String caption,
    required String category,
    required BuildContext context,
    required HomeViewModel homeViewModel,
  }) async {
    final mimeType = lookupMimeType(imageFile.path);
    if (mimeType != null && !mimeType.startsWith('image/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is not an image!')),
      );
      return;
    }
    await _uploadPost(
      file: imageFile,
      caption: caption,
      category: category,
      type: 'image',
      context: context,
      homeViewModel: homeViewModel,
    );
  }

  Future<void> uploadVideoPost({
    required File videoFile,
    required String caption,
    required String category,
    required BuildContext context,
    required HomeViewModel homeViewModel,
    File? customThumbnail,
  }) async {
    final mimeType = lookupMimeType(videoFile.path);
    final ext = videoFile.path.split('.').last.toLowerCase();
    final validVideoExtensions = ['mp4', 'mov', 'mkv', 'mpeg', '3gp', '3gpp', 'avi'];

    if ((mimeType == null || !mimeType.startsWith('video/')) &&
        !validVideoExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is not a valid video!')),
      );
      return;
    }

    final videoSpecs = await _videoService.validateVideo(videoFile);
    if (!videoSpecs['isValidDuration']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video exceeds 60-second limit!')),
      );
      return;
    }

    final width = videoSpecs['width'] as int;
    final height = videoSpecs['height'] as int;

    if ((width > 3840 || height > 2160) && (width > 2160 || height > 3840)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Video resolution exceeds 4K (3840x2160 or 2160x3840) limit!')),
      );
      return;
    }

    File? compressedVideo;
    if (width <= 854 && height <= 480) {
      compressedVideo = videoFile;
    } else {
      compressedVideo = await _videoService.compressVideo(videoFile, context);
    }
    if (compressedVideo == null) {
      return;
    }

    await _uploadPost(
      file: compressedVideo,
      caption: caption,
      category: category,
      type: 'video',
      context: context,
      homeViewModel: homeViewModel,
      videoFile: compressedVideo,
      customThumbnail: customThumbnail,
    );
  }

  Future<void> _uploadPost({
    required File file,
    required String caption,
    required String category,
    required String type,
    required BuildContext context,
    required HomeViewModel homeViewModel,
    File? videoFile,
    File? customThumbnail,
  }) async {
    final trimmedCaption = caption.trim();
    if (trimmedCaption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption cannot be empty!')),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final hashtags = _extractHashtags(trimmedCaption);
      final mentions = await _extractMentions(trimmedCaption);
      final normalizedCategory = category.trim().isEmpty
          ? 'Uncategorized'
          : category.trim().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');

      final ext = file.path.split('.').last;
      final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storageRef = FirebaseStorage.instance.ref().child('posts/$filename');

      const maxRetries = 3;
      int attempt = 0;
      String? fileUrl;

      while (attempt < maxRetries) {
        try {
          final uploadTask = await storageRef.putFile(file);
          fileUrl = await uploadTask.ref.getDownloadURL();
          break;
        } catch (e) {
          attempt++;
          if (attempt == maxRetries) {
            throw Exception('Failed to upload file after $maxRetries attempts: $e');
          }
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      if (fileUrl == null) {
        throw Exception('Failed to obtain file URL');
      }

      String? thumbnailUrl;
      if (type == 'video') {
        if (customThumbnail != null) {
          final thumbExt = customThumbnail.path.split('.').last;
          final thumbFilename =
              '${DateTime.now().millisecondsSinceEpoch}_thumb.$thumbExt';
          final thumbRef =
          FirebaseStorage.instance.ref().child('thumbnails/$thumbFilename');
          final thumbUploadTask = await thumbRef.putFile(customThumbnail);
          thumbnailUrl = await thumbUploadTask.ref.getDownloadURL();
        } else if (videoFile != null) {
          thumbnailUrl =
          await _videoService.generateAndUploadThumbnail(videoFile, userId);
        }
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc();

      final newPost = {
        'imageUrl': type == 'image' ? fileUrl : '',
        'videoUrl': type == 'video' ? fileUrl : '',
        'thumbnailUrl': thumbnailUrl ?? '',
        'caption': trimmedCaption,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'username': userData['username'] ?? '',
        'userProfilePic': userData['profile_picture'] ?? '',
        'hashtags': hashtags.map((h) => h.toLowerCase()).toList(),
        'mentions': mentions,
        'category': normalizedCategory,
        'type': type,
        'isArchived': false,
        'commentsDisabled': false,
      };

      await postRef.set(newPost);

      // Create notifications for mentioned users
      for (var username in mentions) {
        final mentionedUserDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        if (mentionedUserDoc.docs.isNotEmpty) {
          final mentionedUserId = mentionedUserDoc.docs.first.id;
          await NotificationService.createNotification(
            recipientId: mentionedUserId,
            type: 'mention',
            relatedPostId: postRef.id,
            postOwnerId: userId,
            postId: postRef.id,
            extraMessage: '${userData['username']} mentioned you in a post.',
          );
        }
      }

      await homeViewModel.fetchPosts();
      await showNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      print('Uploaded a $type post successfully!');
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload post: $e')),
      );
    }
  }

  List<String> _extractHashtags(String caption) {
    final RegExp hashtagRegex = RegExp(r'\B#\w\w+');
    return hashtagRegex.allMatches(caption).map((match) => match.group(0)!).toList();
  }

  Future<List<String>> _extractMentions(String caption) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final mentions = mentionRegex
        .allMatches(caption)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
    final validatedMentions = <String>[];
    for (var username in mentions) {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        validatedMentions.add(username);
      }
    }
    return validatedMentions;
  }
}