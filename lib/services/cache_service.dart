import 'chat_history_service.dart';
import 'news_cache_service.dart';
import 'reading_history_service.dart';
import 'search_history_service.dart';

class CacheService {
  CacheService._();

  static Future<void> clearAll() async {
    await Future.wait([
      ReadingHistoryService.clear(),
      SearchHistoryService.clear(),
      ChatHistoryService.clear(),
      NewsCacheService.clear(),
    ]);
  }
}
