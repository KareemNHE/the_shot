//viewmodels/message_list_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/search_model.dart';
import '../models/message_model.dart';


class MessageListViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<ChatSummary> recentChats = [];
  List<SearchUser> searchedUsers = [];
  bool isSearching = false;

  void loadChats() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<ChatSummary> chats = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final chatPartnerId = doc.id;

        final userDoc = await _firestore.collection('users').doc(chatPartnerId).get();
        final userData = userDoc.data() ?? {};

        final lastMsg = data['lastMessage'] ?? '';
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final isMe = data['senderId'] == currentUserId;
        final isUnread = data['isRead'] == false && !isMe;

        chats.add(ChatSummary(
          receiverId: chatPartnerId,
          receiverUsername: userData['username'] ?? 'Unknown',
          receiverProfilePic: userData['profile_picture'] ?? '',
          lastMessage: lastMsg,
          timestamp: timestamp,
          isLastMessageFromMe: isMe,
          isUnread: isUnread,
        ));
      }

      recentChats = chats;
      notifyListeners();
    });
  }




  void searchUsers(String query) async {
    isSearching = query.isNotEmpty;

    if (query.isEmpty) {
      searchedUsers = [];
      notifyListeners();
      return;
    }

    final snapshot = await _firestore.collection('users').get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data();
      return SearchUser(
        id: doc.id,
        username: data['username'] ?? '',
        first_name: data['first_name'] ?? '',
        last_name: data['last_name'] ?? '',
        profile_picture: data['profile_picture'] ?? '',
      );
    }).where((user) {
      final lowerQuery = query.toLowerCase();
      return user.username.toLowerCase().contains(lowerQuery) ||
          user.first_name.toLowerCase().contains(lowerQuery) ||
          user.last_name.toLowerCase().contains(lowerQuery);
    }).toList();

    searchedUsers = results;
    notifyListeners();
  }

  int get unreadCount {
    return recentChats.where((chat) => chat.isUnread).length;
  }
}


