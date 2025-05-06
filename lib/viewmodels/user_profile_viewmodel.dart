//viewmodels/user_profile_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/search_model.dart';
import '../models/post_model.dart';
import '../services/notification_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  SearchUser? _user;
  List<PostModel> _posts = [];

  SearchUser? get user => _user;
  List<PostModel> get posts => _posts;

  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  int _followersCount = 0;
  int _followingCount = 0;

  int get followersCount => _followersCount;
  int get followingCount => _followingCount;

  Future<bool> _isUserBlocked(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(userId)
        .get();
    return doc.exists;
  }

  Future<void> toggleFollow(String otherUserId) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(otherUserId);

    final followerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .collection('followers')
        .doc(currentUserId);

    if (_isFollowing) {
      await ref.delete();
      await followerRef.delete();
    } else {
      await ref.set({});
      await followerRef.set({});
    }

    if (!_isFollowing) {
      await NotificationService.createNotification(
        recipientId: otherUserId,
        type: 'follow',
      );
    }

    _isFollowing = !_isFollowing;
    notifyListeners();
  }

  Future<void> fetchUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is blocked
      if (await _isUserBlocked(userId)) {
        _user = null;
        _posts = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _user = SearchUser(
          id: userDoc.id,
          username: data['username'],
          first_name: data['first_name'],
          last_name: data['last_name'],
          profile_picture: data['profile_picture'] ?? 'assets/default_profile.png',
          bio: data['bio'] ?? '',
        );
      }

      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();

      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      _followersCount = followersSnapshot.size;
      _followingCount = followingSnapshot.size;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final followDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(userId)
            .get();

        _isFollowing = followDoc.exists;
      }

      // Fetch user's posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      _posts = postsSnapshot.docs.map((doc) {
        return PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
