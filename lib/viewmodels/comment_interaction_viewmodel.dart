//viewmodels/comment_interaction_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentInteractionViewModel extends ChangeNotifier {
  final String postId;
  final String commentId;
  final String postOwnerId;

  bool isLiked = false;
  int likeCount = 0;

  CommentInteractionViewModel({
    required this.postId,
    required this.commentId,
    required this.postOwnerId,
  }) {
    fetchLikes();
  }

  Future<void> fetchLikes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes');

    try {
      final likeDoc = await docRef.doc(uid).get();
      isLiked = likeDoc.exists;

      final likesSnapshot = await docRef.get();
      likeCount = likesSnapshot.docs.length;
    } catch (e) {
      print('Error fetching comment likes: $e');
    }

    notifyListeners();
  }

  Future<void> toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid);

    try {
      if (isLiked) {
        await ref.delete();
        likeCount--;
      } else {
        await ref.set({'timestamp': FieldValue.serverTimestamp()});
        likeCount++;
      }

      isLiked = !isLiked;
    } catch (e) {
      print('Error toggling comment like: $e');
    }

    notifyListeners();
  }
}
