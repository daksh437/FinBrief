import '../models/watchlist_item.dart';
import 'api_service.dart';

class WatchlistService {
  WatchlistService._();
  static final WatchlistService instance = WatchlistService._();

  Future<List<WatchlistItem>> list() async {
    final res = await ApiService.instance.get('/watchlist');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((w) => WatchlistItem.fromJson(w)).toList();
  }

  Future<bool> add(String symbol, {String? name, double? alertPrice, String type = 'Stocks'}) async {
    final res = await ApiService.instance.post('/watchlist', body: {
      'symbol': symbol,
      'name': name,
      'alertPrice': alertPrice,
      'type': type,
    });
    return res['success'] == true;
  }

  Future<bool> updateAlertPrice(String symbol, double? alertPrice) async {
    final res = await ApiService.instance.patch('/watchlist/$symbol', body: {'alertPrice': alertPrice});
    return res['success'] == true;
  }

  Future<bool> remove(String symbol) async {
    final res = await ApiService.instance.delete('/watchlist/$symbol');
    return res['success'] == true;
  }
}
