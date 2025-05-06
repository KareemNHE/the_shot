//viewmodels/news_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_shot2/models/news_article.dart';
import 'package:the_shot2/models/sport_category.dart';
import 'package:the_shot2/services/news_service.dart';

class NewsViewModel extends ChangeNotifier {
  final NewsService _newsService;

  List<SportCategory> _sports = [
    SportCategory(name: 'Football', query: 'soccer'),
    SportCategory(name: 'Basketball', query: 'basketball'),
    SportCategory(name: 'Tennis', query: 'tennis'),
    SportCategory(name: 'Cricket', query: 'cricket'),
    SportCategory(name: 'Rugby', query: 'rugby'),
    SportCategory(name: 'American Football', query: 'american football'),
    SportCategory(name: 'Gymnastics', query: 'gymnastics'),
    SportCategory(name: 'MMA', query: 'mma'),
    SportCategory(name: 'Golf', query: 'golf'),
    SportCategory(name: 'Darts', query: 'darts'),
    SportCategory(name: 'Bodybuilding', query: 'bodybuilding'),
    SportCategory(name: 'F1', query: 'f1'),
    SportCategory(name: 'Baseball', query: 'baseball'),
  ];
  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _sortMode = 'relevancy';
  String _sportSearchQuery = '';
  String _articleSearchQuery = '';

  NewsViewModel({required NewsService newsService}) : _newsService = newsService;

  List<SportCategory> get sports => _sports;
  List<NewsArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sortMode => _sortMode;
  String get sportSearchQuery => _sportSearchQuery;
  String get articleSearchQuery => _articleSearchQuery;

  List<SportCategory> get filteredSports => _sportSearchQuery.isEmpty
      ? _sports
      : _sports
      .where((sport) =>
      sport.name.toLowerCase().contains(_sportSearchQuery.toLowerCase()))
      .toList();

  List<NewsArticle> get filteredArticles => _articleSearchQuery.isEmpty
      ? _articles
      : _articles.where((article) {
    final query = _articleSearchQuery.toLowerCase();
    final title = article.title.toLowerCase();
    final description =
        article.description?.toLowerCase() ?? '';
    final dateFormat = DateFormat('yyyy-MM-dd');
    final publishedDate = dateFormat.format(article.publishedAt);

    // Try parsing query as a date
    bool isDateMatch = false;
    try {
      final parsedDate = dateFormat.parse(query, true);
      isDateMatch = parsedDate.year == article.publishedAt.year &&
          parsedDate.month == article.publishedAt.month &&
          parsedDate.day == article.publishedAt.day;
    } catch (e) {
      // Not a valid date format
    }

    // Match team, event, or date
    return title.contains(query) ||
        description.contains(query) ||
        isDateMatch ||
        publishedDate.contains(query);
  }).toList();

  Future<void> fetchNewsForSport(String sportQuery, {String? sortMode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _articles = await _newsService.fetchNewsBySport(
        sportQuery,
        sortMode: sortMode ?? _sortMode,
      );
      if (sortMode == 'latest' || _sortMode == 'latest') {
        _articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      } else if (sortMode == 'oldest' || _sortMode == 'oldest') {
        _articles.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      }
    } catch (e) {
      _errorMessage = 'Failed to load news: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSortMode(String sortMode) {
    _sortMode = sortMode;
    notifyListeners();
  }

  void setSportSearchQuery(String query) {
    _sportSearchQuery = query;
    notifyListeners();
  }

  void setArticleSearchQuery(String query) {
    _articleSearchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}