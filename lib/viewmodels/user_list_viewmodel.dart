//viewmodels/user_list_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/search_model.dart';

class UserListViewModel extends ChangeNotifier {
  List<SearchUser> _users = [];
  bool _isLoading = true;

  List<SearchUser> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsersFromIds(List<String> userIds) async {
    _isLoading = true;
    notifyListeners();

    List<SearchUser> loadedUsers = [];

    for (String id in userIds) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        loadedUsers.add(SearchUser(
          id: doc.id,
          username: data['username'],
          first_name: data['first_name'],
          last_name: data['last_name'],
          profile_picture: data['profile_picture'] ?? 'assets/default_profile.png',
        ));
      }
    }

    _users = loadedUsers;
    _isLoading = false;
    notifyListeners();
  }
}
