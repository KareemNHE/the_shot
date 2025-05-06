//viewmodels/settings_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:the_shot2/models/search_model.dart';
import 'package:the_shot2/services/settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _settingsService;

  bool _isPrivate = false;
  String _themePreference = 'light';
  Map<String, bool> _notificationSettings = {
    'likes': true,
    'comments': true,
    'follows': true,
    'messages': true,
  };
  List<SearchUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _language = 'English';
  bool _twoFactorAuth = false;
  bool _dataSaver = false;

  SettingsViewModel({required SettingsService settingsService})
      : _settingsService = settingsService {
    fetchSettings();
  }

  bool get isPrivate => _isPrivate;
  String get themePreference => _themePreference;
  Map<String, bool> get notificationSettings => _notificationSettings;
  List<SearchUser> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get language => _language;
  bool get twoFactorAuth => _twoFactorAuth;
  bool get dataSaver => _dataSaver;

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = await _settingsService.getUserSettings();
      if (settings != null) {
        _isPrivate = settings['isPrivate'] ?? false;
        _themePreference = settings['themePreference'] ?? 'light';
        _notificationSettings = (settings['notificationSettings'] as Map<String, dynamic>?)?.cast<String, bool>() ?? {
          'likes': true,
          'comments': true,
          'follows': true,
          'messages': true,
        };
        await _fetchBlockedUsers();
      }
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchBlockedUsers() async {
    final blockedList = await _settingsService.getBlockedUsers();
    final userIds = blockedList.map((user) => user['id'] as String).toList();
    _blockedUsers = await _getUserDetails(userIds);
    notifyListeners();
  }

  Future<List<SearchUser>> _getUserDetails(List<String> userIds) async {
    List<SearchUser> users = [];
    for (String id in userIds) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        users.add(SearchUser(
          id: doc.id,
          username: data['username'] ?? 'Unknown',
          first_name: data['first_name'] ?? '',
          last_name: data['last_name'] ?? '',
          profile_picture: data['profile_picture'] ?? 'assets/default_profile.png',
        ));
      }
    }
    return users;
  }

  Future<void> toggleProfileVisibility(bool value) async {
    try {
      await _settingsService.updateProfileVisibility(value);
      _isPrivate = value;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile visibility: $e';
      notifyListeners();
    }
  }

  Future<void> toggleTheme(String theme) async {
    try {
      await _settingsService.updateThemePreference(theme);
      _themePreference = theme;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update theme: $e';
      notifyListeners();
    }
  }

  Future<void> toggleNotificationSetting(String type, bool value) async {
    try {
      _notificationSettings[type] = value;
      await _settingsService.updateNotificationSettings(_notificationSettings);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update notification settings: $e';
      notifyListeners();
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _settingsService.unblockUser(userId);
      _blockedUsers = _blockedUsers.where((user) => user.id != userId).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to unblock user: $e';
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
  }

  Future<void> toggleTwoFactorAuth(bool value) async {
    _twoFactorAuth = value;
    notifyListeners();
  }

  Future<void> toggleDataSaver(bool value) async {
    _dataSaver = value;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      await _settingsService.deleteAccount();
    } catch (e) {
      _errorMessage = 'Failed to delete account: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}