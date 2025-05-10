//viewmodels/post_detail_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostDetailViewModel extends ChangeNotifier {
  PostModel? _post;
  bool _isLoading = true;
  String? _errorMessage;

  PostModel? get post => _post;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPost(String postId, String postOwnerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId)
          .get();

      final data = doc.data();
      if (data != null) {
        PostModel post = PostModel.fromFirestore(data, doc.id);

        if (post.username == 'Unknown' || post.userProfilePic.isEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(post.userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            post = PostModel(
              id: post.id,
              userId: post.userId,
              username: userData['username'] ?? 'Unknown',
              userProfilePic: userData['profile_picture'] ?? '',
              imageUrl: post.imageUrl,
              videoUrl: post.videoUrl,
              thumbnailUrl: post.thumbnailUrl,
              caption: post.caption,
              timestamp: post.timestamp,
              hashtags: post.hashtags,
              mentions: post.mentions,
              category: post.category,
              type: post.type,
              isArchived: post.isArchived,
              commentsDisabled: post.commentsDisabled,
            );
          }
        }

        _post = post;
        _errorMessage = null;
      } else {
        _errorMessage = 'Post not found';
      }
    } catch (e) {
      _errorMessage = 'Error fetching post: $e';
      print('Error fetching post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPost(PostModel post) {
    _post = post;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}