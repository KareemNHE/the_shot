//viewmodels/user_post_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class UserPostsViewModel extends ChangeNotifier {
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      _userPosts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Fetched ${_userPosts.length} posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching user posts: $e';
      print('Error fetching user posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}