// viewmodels/profile_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_shot2/models/post_model.dart';

class ProfileViewModel extends ChangeNotifier {
  String _username = '';
  String _profilePictureUrl = '';
  String _bio = '';
  int _followersCount = 0;
  int _followingCount = 0;
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get username => _username;
  String get profilePictureUrl => _profilePictureUrl;
  String get bio => _bio;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final data = userDoc.data() ?? {};
      _username = data['username'] ?? user.email ?? 'Unknown';
      _profilePictureUrl = data['profile_picture']?.isNotEmpty == true
          ? data['profile_picture']
          : 'assets/default_profile.png';
      _bio = (data['bio'] ?? '').isNotEmpty ? data['bio'] : '';

      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .get();
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      _followersCount = followersSnapshot.size;
      _followingCount = followingSnapshot.size;

      await fetchUserPosts(user.uid);
    } catch (e) {
      _errorMessage = 'Error fetching user profile: $e';
      print('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPosts(String userId) async {
    try {
      print('Fetching posts for user $userId');
      // Step 1: Fetch posts with isArchived: false
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      print('Queried posts with isArchived: false: ${postsSnapshot.docs.length} documents found');
      for (var doc in postsSnapshot.docs) {
        print('Post ${doc.id}: ${doc.data()}');
      }

      List<PostModel> userPosts = postsSnapshot.docs.map((doc) {
        return PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Step 2: Fetch all posts to find and fix isArchived: null
      final allPostsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      print('Queried all posts: ${allPostsSnapshot.docs.length} documents found');
      for (var doc in allPostsSnapshot.docs) {
        print('Post ${doc.id}: isArchived=${doc.data()['isArchived']}');
        if (doc.data()['isArchived'] == null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('posts')
              .doc(doc.id)
              .update({'isArchived': false});
          print('Fixed Post ${doc.id}: set isArchived=false');
          // Add fixed post to userPosts if not already included
          if (!userPosts.any((post) => post.id == doc.id)) {
            userPosts.add(PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
          }
        }
      }

      // Sort userPosts by timestamp to maintain order
      userPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _userPosts = userPosts;

      print('Fetched ${_userPosts.length} posts');
      if (_userPosts.isEmpty) {
        print('No non-archived posts found.');
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching user posts: $e';
      print('Error fetching user posts: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}