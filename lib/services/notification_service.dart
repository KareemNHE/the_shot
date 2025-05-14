//services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<bool> _checkNotificationSettings(
      String recipientId, String type) async {
    final doc = await _firestore.collection('users').doc(recipientId).get();
    final settings = doc.data()?['notificationSettings'] as Map<String, dynamic>? ??
        {
          'likes': true,
          'comments': true,
          'follows': true,
          'messages': true,
          'mentions': true,
        };
    final settingsKey = type == 'like'
        ? 'likes'
        : type == 'comment'
        ? 'comments'
        : type == 'follow'
        ? 'follows'
        : type == 'message'
        ? 'messages'
        : type == 'mention'
        ? 'mentions'
        : type;
    return settings[settingsKey] ?? true;
  }

  static Future<void> createNotification({
    required String recipientId,
    required String type,
    String? relatedPostId,
    String? postOwnerId,
    String? extraMessage,
    String? postId,
    String? commentId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == recipientId) return;

    if (!(await _checkNotificationSettings(recipientId, type))) return;

    final blockedDoc = await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('blockedUsers')
        .doc(currentUser.uid)
        .get();
    if (blockedDoc.exists) return;

    final senderSnapshot =
    await _firestore.collection('users').doc(currentUser.uid).get();
    final senderData = senderSnapshot.data();

    final notification = AppNotification(
      id: _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc()
          .id,
      type: type,
      fromUserId: currentUser.uid,
      postId: postId,
      commentId: commentId,
      isRead: false,
      timestamp: DateTime.now(),
      senderId: currentUser.uid,
      senderUsername: senderData?['username'] ?? 'Someone',
      senderProfilePic: senderData?['profile_picture'] ?? 'assets/default_profile.png',
      relatedPostId: relatedPostId,
      message: extraMessage,
      postOwnerId: postOwnerId,
    );

    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }
}