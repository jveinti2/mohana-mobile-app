class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String imageUrl;
  final String category;
  final String author;
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.imageUrl,
    required this.category,
    required this.author,
    required this.publishedAt,
  });
}
