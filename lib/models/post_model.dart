//models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userProfilePic;
  final String imageUrl;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final DateTime timestamp;
  final List<String> hashtags;
  final List<String> mentions;
  final String category;
  final String type; // "image" or "video"
  final bool isArchived;
  final bool commentsDisabled;


  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePic,
    required this.imageUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.timestamp,
    required this.hashtags,
    required this.mentions,
    required this.category,
    required this.type,
    this.isArchived = false,
    this.commentsDisabled = false,
  });

  factory PostModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown User',
      userProfilePic: data['userProfilePic'] ?? '',
      imageUrl: data['imageUrl'] ?? '', // just in case
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      caption: data['caption'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      category: data['category'] ?? 'Uncategorized',
      type: (data['type'] ?? 'video').toString(),
      isArchived: data['isArchived'] ?? false,
      commentsDisabled: data['commentsDisabled'] ?? false,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'hashtags': hashtags,
      'mentions': mentions,
      'category': category,
      'type': type,
      'isArchived': isArchived,
      'commentsDisabled': commentsDisabled,
    };
  }
}
