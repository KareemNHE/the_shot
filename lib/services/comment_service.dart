//services/comment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import 'notification_service.dart';

class CommentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> addComment({
    required String postId,
    required String postOwnerId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc =
    await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? {};

    final mentions = await _extractMentions(text);
    final comment = CommentModel(
      id: '',
      userId: currentUser.uid,
      username: userData['username'] ?? 'Unknown',
      userProfilePic: userData['profile_picture'] ?? '',
      text: text,
      timestamp: DateTime.now(),
      mentions: mentions,
    );

    final ref = _firestore
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    await ref.set({
      ...comment.toMap(),
      'id': ref.id,
    });

    if (currentUser.uid != postOwnerId) {
      await NotificationService.createNotification(
        recipientId: postOwnerId,
        type: 'comment',
        relatedPostId: postId,
        postOwnerId: postOwnerId,
        postId: postId,
        commentId: ref.id,
      );
    }

    for (var username in mentions) {
      final mentionedUserDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (mentionedUserDoc.docs.isNotEmpty) {
        final mentionedUserId = mentionedUserDoc.docs.first.id;
        await NotificationService.createNotification(
          recipientId: mentionedUserId,
          type: 'mention',
          relatedPostId: postId,
          postOwnerId: postOwnerId,
          postId: postId,
          commentId: ref.id,
          extraMessage: '${userData['username']} mentioned you in a comment.',
        );
      }
    }
  }

  static Future<List<CommentModel>> fetchComments({
    required String postId,
    required String postOwnerId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<List<String>> _extractMentions(String text) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final mentions = mentionRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
    final validatedMentions = <String>[];
    for (var username in mentions) {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        validatedMentions.add(username);
      }
    }
    return validatedMentions;
  }
}