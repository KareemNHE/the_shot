// viewmodels/post_interaction_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class PostInteractionViewModel extends ChangeNotifier {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> fetchInteractionData(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('likes')
          .doc(uid)
          .get();

      isLiked = likeDoc.exists;

      final likeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('likes')
          .get();

      likeCount = likeSnapshot.docs.length;

      final commentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('comments')
          .get();

      commentCount = commentSnapshot.docs.length;

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching interaction data: $e';
      print('Error fetching interaction data: $e');
    }
  }

  Future<void> toggleLike(String postId, String postOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid);

    try {
      if (isLiked) {
        await ref.delete();
        likeCount--;
      } else {
        await ref.set({'timestamp': FieldValue.serverTimestamp()});
        await NotificationService.createNotification(
          recipientId: postOwnerId,
          type: 'like',
          relatedPostId: postId,
        );
        likeCount++;
      }

      isLiked = !isLiked;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error toggling like: $e';
      print('Error toggling like: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}