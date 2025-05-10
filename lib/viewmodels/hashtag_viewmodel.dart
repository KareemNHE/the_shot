//viewmodels/hashtag_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/hashtag_service.dart';

class HashtagViewModel extends ChangeNotifier {
  final HashtagService _service;
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  HashtagViewModel({required HashtagService service, String? hashtag}) : _service = service {
    if (hashtag != null) {
      fetchPostsByHashtag(hashtag);
    }
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPostsByHashtag(String hashtag) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _service.fetchPostsByHashtag(hashtag);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load posts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}