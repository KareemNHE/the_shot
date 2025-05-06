// viewmodels/search_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_shot2/models/search_model.dart';
import 'package:the_shot2/services/api_service.dart';
import 'package:the_shot2/models/post_model.dart';

class SearchViewModel extends ChangeNotifier {
  final ApiService apiService;

  SearchViewModel({required this.apiService});

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  List<PostModel> _allPosts = [];
  List<SearchUser> _allUsers = [];

  List<PostModel> _filteredPosts = [];
  List<SearchUser> _filteredUsers = [];
  List<PostModel> _filteredHashtagPosts = [];
  List<PostModel> _filteredUserPosts = [];

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  List<PostModel> get allPosts => _filteredPosts;
  List<SearchUser> get filteredUsers => _filteredUsers;
  List<PostModel> get filteredHashtagPosts => _filteredHashtagPosts;
  List<PostModel> get filteredUserPosts => _filteredUserPosts;

  Future<void> fetchAllUserPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      QuerySnapshot postsSnapshot;
      try {
        // Try query with isArchived filter
        postsSnapshot = await FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('isArchived', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();
        print('Queried posts with isArchived: false: ${postsSnapshot.docs.length} documents found');
      } catch (e) {
        // Fallback if index is missing
        print('Index error for isArchived query: $e');
        postsSnapshot = await FirebaseFirestore.instance
            .collectionGroup('posts')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();
        print('Fallback query without isArchived: ${postsSnapshot.docs.length} documents found');
      }

      List<PostModel> tempPosts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Post ${doc.id}: isArchived=${data['isArchived']}');
        return PostModel.fromFirestore(data, doc.id);
      }).toList();

      // Filter out archived posts in case fallback query was used
      tempPosts = tempPosts.where((post) => !post.isArchived).toList();
      print('Filtered non-archived posts: ${tempPosts.length} posts');

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();

      _allUsers = usersSnapshot.docs.map((doc) {
        return SearchUser(
          id: doc.id,
          username: doc['username'] ?? '',
          first_name: doc['first_name'] ?? '',
          last_name: doc['last_name'] ?? '',
          profile_picture: doc['profile_picture'] ?? '',
          bio: doc.data().containsKey('bio') ? doc['bio'] ?? '' : '',
        );
      }).toList();

      final Map<String, dynamic> userMap = {
        for (var user in usersSnapshot.docs) user.id: user.data(),
      };

      _allPosts = tempPosts.map((post) {
        final userData = userMap[post.userId];
        return PostModel(
          id: post.id,
          userId: post.userId,
          username: userData?['username'] ?? 'Unknown',
          userProfilePic: userData?['profile_picture'] ?? '',
          imageUrl: post.imageUrl,
          videoUrl: post.videoUrl,
          thumbnailUrl: post.thumbnailUrl,
          caption: post.caption,
          timestamp: post.timestamp,
          hashtags: post.hashtags,
          category: post.category,
          type: post.type,
          isArchived: post.isArchived,
        );
      }).toList();

      _filteredPosts = List.from(_allPosts);
      _filteredUsers = List.from(_allUsers);
      _filteredHashtagPosts = [];
      _filteredUserPosts = [];
    } catch (e) {
      _errorMessage = 'Failed to refresh posts: $e';
      print('Error fetching search posts: $e');
    }

    if (isRefresh) {
      _isRefreshing = false;
    } else {
      _isLoading = false;
    }
    notifyListeners();
  }

  void search(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.isEmpty) {
      _filteredPosts = List.from(_allPosts);
      _filteredUsers = [];
      _filteredHashtagPosts = [];
      _filteredUserPosts = [];
    } else {
      _filteredUsers = _allUsers.where((user) {
        return user.username.toLowerCase().contains(lowerQuery) ||
            user.first_name.toLowerCase().contains(lowerQuery) ||
            user.last_name.toLowerCase().contains(lowerQuery);
      }).take(5).toList();

      _filteredHashtagPosts = _allPosts.where((post) {
        return post.hashtags.any((hashtag) => hashtag.toLowerCase().contains(lowerQuery));
      }).toList();

      _filteredUserPosts = _allPosts.where((post) {
        return post.username.toLowerCase().contains(lowerQuery);
      }).toList();

      _filteredPosts = _allPosts.where((post) {
        return post.caption.toLowerCase().contains(lowerQuery) ||
            post.category.toLowerCase().contains(lowerQuery) ||
            post.hashtags.any((hashtag) => hashtag.toLowerCase().contains(lowerQuery)) ||
            post.username.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}