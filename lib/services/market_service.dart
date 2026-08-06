import '../models/ai_insight.dart';
import '../models/ai_pick.dart';
import '../models/market_overview.dart';
import '../models/quote.dart';
import 'api_service.dart';

class MarketService {
  MarketService._();
  static final MarketService instance = MarketService._();

  Future<MarketOverview> getOverview() async {
    final res = await ApiService.instance.get('/market/overview');
    if (res['success'] != true) return MarketOverview.empty();
    return MarketOverview.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<AiInsight?> getInsight() async {
    final res = await ApiService.instance.get('/market/insight');
    if (res['success'] != true) return null;
    return AiInsight.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<AiPick>> getAiPicks() async {
    final res = await ApiService.instance.get('/market/ai-picks');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((p) => AiPick.fromJson(p)).toList();
  }

  /// Live quotes keyed by symbol. Symbols the source couldn't resolve are
  /// simply absent — callers fall back to the user's own figures rather than
  /// showing an invented price.
  ///
  /// Returns [Quote] rather than a bare double because the price alone left
  /// every screen guessing the currency, and they all guessed rupees.
  Future<Map<String, Quote>> getQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    final res = await ApiService.instance.get('/market/quotes', query: {'symbols': symbols.join(',')});
    if (res['success'] != true) return {};
    return {
      for (final q in res['data'] as List)
        (q['symbol'] as String): Quote.fromJson(q as Map<String, dynamic>),
    };
  }
}
