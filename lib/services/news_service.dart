import '../models/news_article.dart';
import 'api_service.dart';
import 'news_cache_service.dart';

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  /// Fetches a page of the feed. On a failed request the **first** page falls
  /// back to the last cached copy so the app stays usable offline; later pages
  /// just return empty (nothing to append).
  Future<List<NewsArticle>> getFeed({
    String category = 'business',
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await ApiService.instance.get(
      '/news/feed',
      query: {'category': category, 'page': page, 'pageSize': pageSize},
    );

    if (res['success'] != true) {
      return page == 1 ? NewsCacheService.load(category) : <NewsArticle>[];
    }

    final articles = (res['data'] as List).map((a) => NewsArticle.fromJson(a)).toList();
    if (page == 1) await NewsCacheService.save(category, articles);
    return articles;
  }

  Future<List<NewsArticle>> search(String query) async {
    final res = await ApiService.instance.get('/news/search', query: {'q': query});
    if (res['success'] != true) return [];
    return (res['data'] as List).map((a) => NewsArticle.fromJson(a)).toList();
  }

  /// Portfolio-aware feed. Returns an empty list when the user has no
  /// holdings yet — the UI shows a prompt to add some rather than an error.
  Future<List<NewsArticle>> getPersonalisedFeed() async {
    final res = await ApiService.instance.get('/feed/personalised');
    if (res['success'] != true) return [];
    final data = res['data'] as Map<String, dynamic>;
    return ((data['articles'] as List?) ?? []).map((a) => NewsArticle.fromJson(a)).toList();
  }

  Future<List<NewsArticle>> getBreaking({int pageSize = 20}) async {
    final res = await ApiService.instance.get('/news/breaking', query: {'pageSize': pageSize});
    if (res['success'] != true) return [];
    return (res['data'] as List).map((a) => NewsArticle.fromJson(a)).toList();
  }

  Future<List<String>> getTrendingSearches() async {
    final res = await ApiService.instance.get('/news/trending-searches');
    if (res['success'] != true) return [];
    return (res['data'] as List).cast<String>();
  }

  Future<List<NewsArticle>> getBookmarks() async {
    final res = await ApiService.instance.get('/news/bookmarks');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((a) => NewsArticle.fromJson(a)).toList();
  }

  Future<bool> addBookmark(NewsArticle article) async {
    final res = await ApiService.instance.post('/news/bookmarks', body: {'article': article.toJson()});
    return res['success'] == true;
  }

  Future<bool> removeBookmark(String id) async {
    final res = await ApiService.instance.delete('/news/bookmarks/$id');
    return res['success'] == true;
  }
}
