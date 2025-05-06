//viewmodels/post_share_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/search_model.dart';
import '../models/message_model.dart';

class PostShareViewModel extends ChangeNotifier {
  final PostModel post;
  final List<String> selectedUserIds = [];

  List<SearchUser> recentUsers = [];
  List<SearchUser> searchedUsers = [];

  bool isSearching = false;

  PostShareViewModel({required this.post}) {
    _loadRecentUsers();
  }

  void toggleSelection(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
    notifyListeners();
  }

  void _loadRecentUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final chats = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    final List<SearchUser> users = [];
    for (var doc in chats.docs) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
      final data = userDoc.data();
      if (data != null) {
        users.add(SearchUser(
          id: doc.id,
          username: data['username'] ?? '',
          first_name: data['first_name'] ?? '',
          last_name: data['last_name'] ?? '',
          profile_picture: data['profile_picture'] ?? '',
        ));
      }
    }

    recentUsers = users;
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    isSearching = query.isNotEmpty;
    if (!isSearching) {
      searchedUsers = [];
      notifyListeners();
      return;
    }

    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    searchedUsers = snapshot.docs
        .map((doc) {
      final data = doc.data();
      return SearchUser(
        id: doc.id,
        username: data['username'] ?? '',
        first_name: data['first_name'] ?? '',
        last_name: data['last_name'] ?? '',
        profile_picture: data['profile_picture'] ?? '',
      );
    })
        .where((user) => user.username.toLowerCase().contains(query.toLowerCase()))
        .toList();

    notifyListeners();
  }

  Future<void> sendPostToSelectedUsers(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || selectedUserIds.isEmpty) return;


    final previewImage = post.imageUrl;
    final previewCaption = post.caption;
    final previewUsername = post.username;
    final previewProfilePic = post.userProfilePic;


    for (final userId in selectedUserIds) {
      final postMessage = MessageModel(
        id: '',
        senderId: currentUserId,
        receiverId: userId,
        text: '',
        timestamp: DateTime.now(),
        sharedPostId: post.id,
        sharedPostThumbnail: previewImage,
        sharedPostCaption: previewCaption,
        sharedPostOwnerUsername: previewUsername,
        sharedPostOwnerProfilePic: previewProfilePic,
      ).toMap();




      final senderChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(userId); // recipient's ID

      final receiverChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // recipient
          .collection('chats')
          .doc(currentUserId); // sender


      // Send message to both sender and receiver chat
      await senderChatRef.collection('messages').add(postMessage);
      await receiverChatRef.collection('messages').add(postMessage);

      // Update chat meta
      await senderChatRef.set({
        'lastMessage': '[Shared a post]',
        'timestamp': Timestamp.now(),
        'senderId': currentUserId,
        'receiverId': userId,
        'isRead': true,
      });

      await receiverChatRef.set({
        'lastMessage': '[Shared a post]',
        'timestamp': Timestamp.now(),
        'senderId': currentUserId,
        'receiverId': userId,
        'isRead': false,
      });
    }

    selectedUserIds.clear();
    notifyListeners();
  }
}
