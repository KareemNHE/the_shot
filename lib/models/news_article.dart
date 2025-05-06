//models/news_article.dart
class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String sportCategory;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.sportCategory,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json, String sportCategory) {
    return NewsArticle(
      id: json['url'] ?? DateTime.now().toIso8601String(),
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      source: json['source']['name'] ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      sportCategory: sportCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'sportCategory': sportCategory,
    };
  }
}