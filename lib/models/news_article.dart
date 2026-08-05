class NewsArticle {
  final String id;
  final String title;
  final String? source;
  final String? url;
  final String? publishedAt;
  final String? summary;
  final String? imageUrl;

  /// Pipeline-assigned metadata (present on processed/personalised feeds).
  final String? category;
  final String? priority;
  final List<String> tags;

  /// Why this article matters to *this* user — null on generic feeds.
  final String? relevanceLabel;
  final bool relevanceDirect;

  NewsArticle({
    required this.id,
    required this.title,
    this.source,
    this.url,
    this.publishedAt,
    this.summary,
    this.imageUrl,
    this.category,
    this.priority,
    this.tags = const [],
    this.relevanceLabel,
    this.relevanceDirect = false,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final relevance = json['relevance'] as Map<String, dynamic>?;

    return NewsArticle(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      source: json['source'] as String?,
      url: json['url'] as String?,
      publishedAt: json['publishedAt'] as String?,
      summary: json['summary'] as String?,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      relevanceLabel: relevance?['label'] as String?,
      relevanceDirect: relevance?['direct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source,
        'url': url,
        'publishedAt': publishedAt,
        'summary': summary,
        'imageUrl': imageUrl,
        'category': category,
        'priority': priority,
        'tags': tags,
      };
}
