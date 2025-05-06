//viewmodels/archived_post_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class ArchivedPostsViewModel extends ChangeNotifier {
  List<PostModel> _archivedPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get archivedPosts => _archivedPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchArchivedPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .orderBy('timestamp', descending: true)
          .get();

      _archivedPosts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Fetched ${_archivedPosts.length} archived posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching archived posts: $e';
      print('Error fetching archived posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}