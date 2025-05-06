//viewmodel/home_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class HomeViewModel extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  HomeViewModel() {
    fetchPosts();
  }

  Future<void> addPost(PostModel post) async {
    _posts.insert(0, post); // Add the new post at the top
    notifyListeners();
  }

  Future<void> fetchPosts() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _errorMessage = 'User not logged in';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final followedIds = await getFollowedUserIds();
      print('Followed user IDs: $followedIds');
      followedIds.add(currentUserId); // Include own posts
      print('Total user IDs (including self): $followedIds');

      List<PostModel> allFetchedPosts = [];

      for (final id in followedIds) {
        // Query posts where isArchived is false or missing
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .get();

        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(id).get();
        final userData = userDoc.data();

        final posts = snapshot.docs.map((doc) {
          final postData = doc.data() as Map<String, dynamic>;
          return PostModel(
            id: doc.id,
            userId: id,
            username: userData?['username'] ?? 'Unknown',
            userProfilePic: userData?['profile_picture'] ?? '',
            imageUrl: postData['imageUrl'] ?? '',
            videoUrl: postData['videoUrl'] ?? '',
            thumbnailUrl: postData['thumbnailUrl'] ?? '',
            caption: postData['caption'] ?? '',
            timestamp: (postData['timestamp'] as Timestamp).toDate(),
            hashtags: List<String>.from(postData['hashtags'] ?? []),
            category: postData['category'] ?? 'Uncategorized',
            type: postData['type'] ?? 'image',
            isArchived: postData['isArchived'] ?? false, // Default to false
            commentsDisabled: postData['commentsDisabled'] ?? false,
          );
        }).where((post) => !post.isArchived).toList();

        print('Fetched ${posts.length} posts for user $id');
        allFetchedPosts.addAll(posts);
      }

      allFetchedPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _posts = allFetchedPosts;
      print('Total posts fetched: ${_posts.length}');
    } catch (e) {
      print('Error fetching posts: $e');
      _errorMessage = 'Failed to load posts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Function to get followed user IDs
  Future<List<String>> getFollowedUserIds() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return [];
    }
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .get();
    final followedIds = snapshot.docs.map((doc) => doc.id).toList();
    return followedIds;
  }
}