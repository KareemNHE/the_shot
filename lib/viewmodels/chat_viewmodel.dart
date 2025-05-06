//viewmodels/chat_viewmodel.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final String otherUserId;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<MessageModel> messages = [];
  bool isLoading = true;

  ChatViewModel({required this.otherUserId}) {
    _listenToMessages();
  }

  void _listenToMessages() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    print('Fetched ${messages.length} messages between $currentUserId and $otherUserId');

    _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .where((msg) =>
      (msg.senderId == currentUserId && msg.receiverId == otherUserId) ||
          (msg.senderId == otherUserId && msg.receiverId == currentUserId))
          .toList();

      final chatRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(otherUserId);

      if (messages.isNotEmpty && messages.first.senderId == otherUserId) {
        await chatRef.update({'isRead': true});
      }


      isLoading = false;
      notifyListeners();
    });
  }


  Future<void> sendMessage(String text) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || text.trim().isEmpty || currentUserId == otherUserId) return;

    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final msgData = message.toMap();

    final senderChatRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(otherUserId);

    final receiverChatRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('chats')
        .doc(currentUserId);

    // Write message
    await senderChatRef.collection('messages').add(msgData);
    await receiverChatRef.collection('messages').add(msgData);

    await senderChatRef.set({
      'lastMessage': message.text,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'isRead': true,

    });

    await receiverChatRef.set({
      'lastMessage': message.text,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'isRead': false,
    });

    // Update UI
    messages.insert(0, message);
    notifyListeners();
  }

  Future<void> sendSharedPost({
    required String postId,
    required String thumbnailUrl,
    required String caption,
    required String postOwnerUsername,
    required String postOwnerProfilePic,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == otherUserId) return;

    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      receiverId: otherUserId,
      text: '',
      timestamp: DateTime.now(),
      sharedPostId: postId,
      sharedPostThumbnail: thumbnailUrl,
      sharedPostCaption: caption,
      sharedPostOwnerUsername: postOwnerUsername,
      sharedPostOwnerProfilePic: postOwnerProfilePic,
    );

    final msgData = message.toMap();

    final senderChatRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(otherUserId);

    final receiverChatRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('chats')
        .doc(currentUserId);

    await senderChatRef.collection('messages').add(msgData);
    await receiverChatRef.collection('messages').add(msgData);

    await senderChatRef.set({
      'lastMessage': '[Shared a post]',
      'timestamp': Timestamp.fromDate(message.timestamp),
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'isRead': true,
    });

    await receiverChatRef.set({
      'lastMessage': '[Shared a post]',
      'timestamp': Timestamp.fromDate(message.timestamp),
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'isRead': false,
    });

    messages.insert(0, message);
    notifyListeners();
  }



}
