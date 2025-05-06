//viewmodels/notification_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  Map<String, bool> _notificationSettings = {
    'likes': true,
    'comments': true,
    'follows': true,
    'messages': true,
  };

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  Map<String, bool> get notificationSettings => _notificationSettings;

  NotificationViewModel() {
    fetchSettingsAndNotifications();
  }

  Future<void> fetchSettingsAndNotifications() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    // Fetch notification settings
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    _notificationSettings = (userDoc.data()?['notificationSettings'] as Map<String, dynamic>?)?.cast<String, bool>() ?? {
      'likes': true,
      'comments': true,
      'follows': true,
      'messages': true,
    };

    // Fetch notifications
    _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((n) {
        final settingsKey = n.type == 'like'
            ? 'likes'
            : n.type == 'comment'
            ? 'comments'
            : n.type == 'follow'
            ? 'follows'
            : n.type == 'message'
            ? 'messages'
            : n.type;
        return _notificationSettings[settingsKey] ?? true;
      })
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}
