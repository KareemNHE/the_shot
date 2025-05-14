// viewmodels/comment_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

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

      _comments = snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching comments: $e';
      print('Error fetching comments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComment(String text) async {
    try {
      await CommentService.addComment(
        postId: postId,
        postOwnerId: postOwnerId,
        text: text,
      );
      await fetchComments(); // Refresh after adding
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