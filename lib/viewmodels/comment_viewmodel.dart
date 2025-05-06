// viewmodels/comment_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../services/notification_service.dart';

class CommentViewModel extends ChangeNotifier {
  final String postId;
  final String postOwnerId;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _commentsDisabled = false;
  String? _errorMessage;

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get commentsDisabled => _commentsDisabled;
  String? get errorMessage => _errorMessage;

  CommentViewModel({
    required this.postId,
    required this.postOwnerId,
  }) {
    fetchComments();
    _fetchPostStatus();
  }

  Future<void> _fetchPostStatus() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        _commentsDisabled = postDoc.data()?['commentsDisabled'] ?? false;
      } else {
        _errorMessage = 'Post not found';
      }
    } catch (e) {
      _errorMessage = 'Error fetching post status: $e';
      print('Error fetching post status: $e');
    }
    notifyListeners();
  }

  Future<void> fetchComments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      _comments = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching comments: $e';
      print('Error fetching comments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComment(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to comment';
      notifyListeners();
      return;
    }

    // Check if comments are disabled and the user is not the post owner
    if (_commentsDisabled && user.uid != postOwnerId) {
      _errorMessage = 'Comments are disabled for this post';
      notifyListeners();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final commentData = {
        'userId': user.uid,
        'username': userData['username'] ?? user.email,
        'userProfilePic': userData['profile_picture'] ?? '',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      await fetchComments(); // Refresh after adding
      await NotificationService.createNotification(
        recipientId: postOwnerId,
        type: 'comment',
        relatedPostId: postId,
        postOwnerId: postOwnerId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add comment: $e';
      print('Error adding comment: $e');
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
