//viewmodels/category_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/category_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _service;
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryViewModel({required CategoryService service, String? category}) : _service = service {
    if (category != null) {
      fetchPostsByCategory(category);
    }
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPostsByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _service.fetchPostsByCategory(category);
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