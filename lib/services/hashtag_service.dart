//services/hashtag_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class HashtagService {
  Future<List<PostModel>> fetchPostsByHashtag(String hashtag) async {
    try {
      final normalizedHashtag = hashtag.toLowerCase();
      print('Fetching posts for hashtag: $normalizedHashtag');
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('posts')
          .where('hashtags', arrayContains: normalizedHashtag)
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      print('Found ${querySnapshot.docs.length} posts for hashtag: $normalizedHashtag');
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PostModel.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching posts by hashtag: $e');
      rethrow;
    }
  }
}