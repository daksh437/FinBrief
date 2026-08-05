import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

// Local snapshot of the last successfully-fetched news feed, per category, so
// the app still shows content when the network (or backend) is unavailable.
// This is a read-through cache only — it never replaces a successful fetch.
class NewsCacheService {
  NewsCacheService._();

  static const _prefix = 'news_cache_';

  static Future<void> save(String category, List<NewsArticle> articles) async {
    if (articles.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$category',
      jsonEncode(articles.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<NewsArticle>> load(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$category');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((a) => NewsArticle.fromJson(a as Map<String, dynamic>)).toList();
    } catch (_) {
      // Corrupt/legacy cache entry — treat as empty rather than crashing.
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
