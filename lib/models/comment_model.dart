// models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String userProfilePic;
  final String text;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePic,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      userId: data['userId'],
      username: data['username'] ?? 'Anonymous',
      userProfilePic: data['userProfilePic'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
