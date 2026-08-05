import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

class ReadingHistoryService {
  ReadingHistoryService._();

  static const _key = 'reading_history';
  static const _maxItems = 30;

  static Future<List<NewsArticle>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => NewsArticle.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> add(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == article.id);
    raw.insert(0, jsonEncode(article.toJson()));
    await prefs.setStringList(_key, raw.take(_maxItems).toList());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
