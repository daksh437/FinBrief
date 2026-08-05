import 'package:firebase_analytics/firebase_analytics.dart';

// Thin wrapper so screens don't depend on the Firebase Analytics API directly
// and event names stay consistent in one place.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin(String method) => _analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) => _analytics.logSignUp(signUpMethod: method);

  Future<void> logArticleOpened(String articleId) =>
      _analytics.logEvent(name: 'article_opened', parameters: {'article_id': articleId});

  Future<void> logAiAction(String action) =>
      _analytics.logEvent(name: 'ai_action', parameters: {'action': action});

  Future<void> logSearch(String query) => _analytics.logSearch(searchTerm: query);

  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
