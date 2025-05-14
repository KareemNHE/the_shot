// models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String userProfilePic;
  final String text;
  final DateTime timestamp;
  final List<String> mentions;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePic,
    required this.text,
    required this.timestamp,
    required this.mentions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'mentions': mentions,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Unknown',
      userProfilePic: map['userProfilePic'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentions: List<String>.from(map['mentions'] ?? []),
    );
  }
}
