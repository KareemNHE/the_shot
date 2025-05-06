//viewmodels/saved_post_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class SavedPostsViewModel extends ChangeNotifier {
  List<PostModel> _savedPosts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool isSaved = false;

  List<PostModel> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavedPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot savedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .get();

      _savedPosts = [];
      for (var doc in savedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final postRef = data['postRef'] as DocumentReference;
        final postDoc = await postRef.get();
        if (postDoc.exists) {
          _savedPosts.add(PostModel.fromFirestore(postDoc.data() as Map<String, dynamic>, postDoc.id));
        }
      }

      print('Fetched ${_savedPosts.length} saved posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching saved posts: $e';
      print('Error fetching saved posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIfPostIsSaved(String postId, String userId) async {
    if (userId.isEmpty) {
      isSaved = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .get();

      isSaved = doc.exists;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error checking saved status: $e';
      print('Error checking saved status: $e');
    }
  }

  Future<void> savePost({
    required String postId,
    required String postOwnerId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .set({
        'postRef': FirebaseFirestore.instance
            .collection('users')
            .doc(postOwnerId)
            .collection('posts')
            .doc(postId),
        'timestamp': FieldValue.serverTimestamp(),
      });
      isSaved = true;
    } catch (e) {
      _errorMessage = 'Failed to save post: $e';
      print('Error saving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .delete();
      isSaved = false;
    } catch (e) {
      _errorMessage = 'Failed to unsave post: $e';
      print('Error unsaving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}