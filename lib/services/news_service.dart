//services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:the_shot2/models/news_article.dart';

class NewsService {
  static const String _apiKey = 'f9b34dc642354a67a90faa5220e34819';
  static const String _baseUrl = 'https://newsapi.org/v2/everything';

  Future<List<NewsArticle>> fetchNewsBySport(String sportQuery,
      {String sortMode = 'relevancy'}) async {
    try {
      final sortParam = (sortMode == 'latest' || sortMode == 'oldest') ? 'publishedAt' : sortMode;
      final query = Uri.encodeQueryComponent('$sportQuery+sports');
      final url = '$_baseUrl?q=$query&language=en&apiKey=$_apiKey&sortBy=$sortParam';
      print('NewsAPI Query: $url');

      final response = await http.get(Uri.parse(url));
      print('NewsAPI Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['articles'] as List<dynamic>)
            .map((article) => NewsArticle.fromJson(article, sportQuery))
            .where((article) => article.url.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      print('NewsAPI Error: $e');
      throw Exception('Error fetching news: $e');
    }
  }
}