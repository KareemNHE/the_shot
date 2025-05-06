//models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'tag', 'follow_request'
  final String fromUserId;
  final String? postId;
  final String? commentId;
  final bool isRead;
  final DateTime timestamp;
  final String senderId;
  final String senderUsername;
  final String senderProfilePic;
  final String? relatedPostId;
  final String? message;
  final String? postOwnerId;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    this.postId,
    this.commentId,
    this.isRead = false,
    required this.timestamp,
    required this.senderId,
    required this.senderUsername,
    required this.senderProfilePic,
    this.relatedPostId,
    this.message,
    this.postOwnerId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      postId: data['postId'],
      commentId: data['commentId'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      senderId: data['senderId'] ?? '',
      senderUsername: data['senderUsername'] ?? 'Unknown',
      senderProfilePic: data['senderProfilePic'] ?? '',
      relatedPostId: data['relatedPostId'],
      message: data['message'],
      postOwnerId: data['postOwnerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfilePic': senderProfilePic,
      'relatedPostId': relatedPostId ?? postId,
      'message': message,
      'postId': postId,
      'commentId': commentId,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'postOwnerId': postOwnerId,
    };
  }
}
