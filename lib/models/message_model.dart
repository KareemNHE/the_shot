//models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String? sharedPostId;
  final String? sharedPostThumbnail;
  final String? sharedPostCaption;
  final String? sharedPostOwnerUsername;
  final String? sharedPostOwnerProfilePic;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.sharedPostId,
    this.sharedPostThumbnail,
    this.sharedPostCaption,
    this.sharedPostOwnerUsername,
    this.sharedPostOwnerProfilePic,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('Parsing message: ${doc.data()}');

    final sender = data['senderId'] ?? data['sharedById'] ?? '';
    final receiver = data['receiverId'] ?? data['sharedToId'] ?? '';

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? (data['type'] == 'post' ? '[Shared a post]' : ''),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      sharedPostId: data['sharedPostId'] ?? data['postId'],
      sharedPostThumbnail: data['sharedPostThumbnail'] ?? data['previewImage'],
      sharedPostCaption: data['sharedPostCaption'] ?? data['previewCaption'],
      sharedPostOwnerUsername: data['sharedPostOwnerUsername'] ?? data['previewUsername'],
      sharedPostOwnerProfilePic: data['sharedPostOwnerProfilePic'] ?? data['previewProfilePic'],

    );
  }


  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'sharedPostId': sharedPostId,
      'sharedPostThumbnail': sharedPostThumbnail,
      'sharedPostCaption': sharedPostCaption,
      'sharedPostOwnerUsername': sharedPostOwnerUsername,
      'sharedPostOwnerProfilePic': sharedPostOwnerProfilePic,
      'type': sharedPostId != null ? 'post' : 'text',
    };
  }
}

class ChatSummary {
  final String receiverId;
  final String receiverUsername;
  final String receiverProfilePic;
  final String? lastMessage;
  final DateTime? timestamp;
  final bool isLastMessageFromMe;
  final bool isUnread;


  ChatSummary({
    required this.receiverId,
    required this.receiverUsername,
    required this.receiverProfilePic,
    this.lastMessage,
    this.timestamp,
    this.isLastMessageFromMe = false,
    this.isUnread = false,
  });
}
