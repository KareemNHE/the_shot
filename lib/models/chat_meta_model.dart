//models/chat_meta_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMetaModel {
  final String lastMessage;
  final DateTime timestamp;
  final String senderId;
  final String receiverId;

  ChatMetaModel({
    required this.lastMessage,
    required this.timestamp,
    required this.senderId,
    required this.receiverId,
  });

  factory ChatMetaModel.fromMap(Map<String, dynamic> data) {
    return ChatMetaModel(
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      senderId: data['senderId'],
      receiverId: data['receiverId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastMessage': lastMessage,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderId': senderId,
      'receiverId': receiverId,
    };
  }
}
