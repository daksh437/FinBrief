import 'ipo_event.dart';
import 'market_item.dart';

class MarketOverview {
  final List<MarketItem> indices;
  final List<MarketItem> crypto;
  final List<MarketItem> gold;
  final List<MarketItem> forex;
  final List<MarketItem> globalMarkets;
  final List<IpoEvent> ipoCalendar;

  MarketOverview({
    required this.indices,
    required this.crypto,
    required this.gold,
    required this.forex,
    required this.ipoCalendar,
    this.globalMarkets = const [],
  });

  factory MarketOverview.empty() =>
      MarketOverview(indices: [], crypto: [], gold: [], forex: [], ipoCalendar: []);

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    List<MarketItem> parseItems(String key) =>
        ((json[key] as List?) ?? []).map((e) => MarketItem.fromJson(e)).toList();

    return MarketOverview(
      indices: parseItems('indices'),
      crypto: parseItems('crypto'),
      gold: parseItems('gold'),
      forex: parseItems('forex'),
      globalMarkets: parseItems('globalMarkets'),
      ipoCalendar: ((json['ipoCalendar'] as List?) ?? []).map((e) => IpoEvent.fromJson(e)).toList(),
    );
  }
}
