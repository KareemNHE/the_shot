//views/widgets/news_tile.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:the_shot2/models/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsTile extends StatelessWidget {
  final NewsArticle article;

  const NewsTile({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final urlString = article.url.trim();
          print('Attempting to open URL: $urlString');
          if (urlString.isEmpty) {
            print('URL is empty');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Article URL is empty')),
            );
            return;
          }
          // Try https first, then http as fallback
          final urlsToTry = [
            urlString.startsWith('http') ? urlString : 'https://$urlString',
            urlString.startsWith('http') ? urlString.replaceFirst('https', 'http') : 'http://$urlString',
          ];
          bool launched = false;
          String? errorMessage;

          for (final urlStr in urlsToTry) {
            final url = Uri.parse(urlStr);
            print('Parsed URL: $url');
            if (await canLaunchUrl(url)) {
              print('canLaunchUrl: true for $url');
              await launchUrl(url, mode: LaunchMode.externalApplication);
              launched = true;
              break;
            } else {
              print('canLaunchUrl: false for $url');
              errorMessage = 'Could not launch $url';
            }
          }

          if (!launched) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage ?? 'Could not open article')),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              CachedNetworkImage(
                imageUrl: article.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.source,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        _formatTime(article.publishedAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    if (duration.inDays < 1) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}