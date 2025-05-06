//services/settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateProfileVisibility(bool isPrivate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not problem in');
    await _firestore.collection('users').doc(userId).update({
      'isPrivate': isPrivate,
    });
  }

  Future<void> updateThemePreference(String theme) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(userId).update({
      'themePreference': theme,
    });
  }

  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(userId).update({
      'notificationSettings': settings,
    });
  }

  Future<void> blockUser(String userIdToBlock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == userIdToBlock) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(userIdToBlock)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Remove from followers/following
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(userIdToBlock)
        .delete();
    await _firestore
        .collection('users')
        .doc(userIdToBlock)
        .collection('followers')
        .doc(currentUserId)
        .delete();
  }

  Future<void> unblockUser(String userIdToUnblock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(userIdToUnblock)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'timestamp': doc['timestamp'],
    }).toList();
  }

  Future<Map<String, dynamic>?> getUserSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> deleteAccount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(userId).delete();
    await _auth.currentUser?.delete();
  }
}