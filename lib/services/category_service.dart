//services/category_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class CategoryService {
  Future<List<PostModel>> fetchPostsByCategory(String category) async {
    try {
      // Normalize to title case
      final normalizedCategory = category.trim().isEmpty
          ? 'Uncategorized'
          : category.trim().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
      print('Fetching posts for category: $normalizedCategory');
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('posts')
          .where('category', isEqualTo: normalizedCategory)
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      print('Found ${querySnapshot.docs.length} posts for category: $normalizedCategory');
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PostModel.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching posts by category: $e');
      rethrow;
    }
  }
}