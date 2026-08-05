import '../models/ai_insight.dart';
import '../models/ai_pick.dart';
import '../models/market_overview.dart';
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

  Future<Map<String, double>> getQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    final res = await ApiService.instance.get('/market/quotes', query: {'symbols': symbols.join(',')});
    if (res['success'] != true) return {};
    return {for (final q in res['data'] as List) (q['symbol'] as String): (q['price'] as num).toDouble()};
  }
}
