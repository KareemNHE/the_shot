// viewmodels/search_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class SearchUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final String bio;

  SearchUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.bio,
  });
}

class SearchViewModel extends ChangeNotifier {
  List<PostModel> _allPosts = [];
  List<SearchUser> _allUsers = [];
  List<PostModel> _filteredPosts = [];
  List<SearchUser> _filteredUsers = [];
  List<PostModel> _filteredHashtagPosts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  List<PostModel> get allPosts => _filteredPosts;
  List<SearchUser> get filteredUsers => _filteredUsers;
  List<PostModel> get filteredHashtagPosts => _filteredHashtagPosts;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  SearchViewModel() {
    fetchAllUserPosts();
  }

  Future<void> fetchAllUserPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      _errorMessage = null;
    } else {
      _isLoading = true;
    }
    notifyListeners();

    try {
      print('Fetching all posts for search');
      QuerySnapshot postsSnapshot;
      try {
        postsSnapshot = await FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('isArchived', isEqualTo: false)
            .where('emailVerified', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();
        print('Queried posts: ${postsSnapshot.docs.length} documents found');
      } catch (e) {
        print('Error fetching posts: $e');
        postsSnapshot = await FirebaseFirestore.instance
            .collectionGroup('posts')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();
        print('Fallback query: ${postsSnapshot.docs.length} documents found');
      }

      _allPosts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Post ${doc.id}: hashtags=${data['hashtags']}, isArchived=${data['isArchived']}');
        return PostModel.fromFirestore(data, doc.id);
      }).where((post) => !post.isArchived).toList();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('emailVerified', isEqualTo: true)
          .limit(100)
          .get();

      _allUsers = usersSnapshot.docs.map((doc) {
        return SearchUser(
          id: doc.id,
          username: doc['username'] ?? '',
          firstName: doc['first_name'] ?? '',
          lastName: doc['last_name'] ?? '',
          profilePicture: doc['profile_picture'] ?? '',
          bio: doc['bio'] ?? '',
        );
      }).toList();

      _filteredPosts = List.from(_allPosts);
      _filteredUsers = [];
      _filteredHashtagPosts = List.from(_allPosts);
      _isLoading = false;
      _isRefreshing = false;
      _errorMessage = null;
      print('Fetched ${_allPosts.length} posts, ${_allUsers.length} users');
    } catch (e) {
      _isLoading = false;
      _isRefreshing = false;
      _errorMessage = 'Failed to fetch posts: $e';
      print('Error fetching search data: $e');
    }
    notifyListeners();
  }

  void search(String query) {
    final lowerQuery = query.toLowerCase();
    final isHashtagQuery = query.startsWith('#');
    final isCategoryQuery = query.startsWith('category:');

    if (lowerQuery.isEmpty) {
      _filteredPosts = List.from(_allPosts);
      _filteredUsers = [];
      _filteredHashtagPosts = List.from(_allPosts);
    } else {
      _filteredUsers = _allUsers.where((user) {
        return user.username.toLowerCase().contains(lowerQuery) ||
            user.firstName.toLowerCase().contains(lowerQuery) ||
            user.lastName.toLowerCase().contains(lowerQuery);
      }).take(5).toList();

      _filteredHashtagPosts = _allPosts.where((post) {
        return post.hashtags.any((hashtag) => hashtag.toLowerCase().contains(lowerQuery));
      }).toList();

      if (isHashtagQuery) {
        _filteredPosts = _filteredHashtagPosts;
      } else if (isCategoryQuery) {
        final categoryQuery = lowerQuery.replaceFirst('category:', '').trim();
        _filteredPosts = _allPosts.where((post) {
          return post.category.toLowerCase().contains(categoryQuery);
        }).toList();
      } else {
        _filteredPosts = _allPosts.where((post) {
          return post.caption.toLowerCase().contains(lowerQuery) ||
              post.category.toLowerCase().contains(lowerQuery) ||
              post.hashtags.any((hashtag) => hashtag.toLowerCase().contains(lowerQuery)) ||
              post.username.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}