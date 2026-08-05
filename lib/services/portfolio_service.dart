import '../models/portfolio_item.dart';
import 'api_service.dart';

class PortfolioService {
  PortfolioService._();
  static final PortfolioService instance = PortfolioService._();

  Future<List<PortfolioItem>> list() async {
    final res = await ApiService.instance.get('/portfolio');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((p) => PortfolioItem.fromJson(p)).toList();
  }

  Future<bool> add(String symbol, {String? name, required double quantity, required double avgPrice}) async {
    final res = await ApiService.instance.post('/portfolio', body: {
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'avgPrice': avgPrice,
    });
    return res['success'] == true;
  }

  Future<bool> remove(String symbol) async {
    final res = await ApiService.instance.delete('/portfolio/$symbol');
    return res['success'] == true;
  }

  Future<String> getInsight() async {
    final res = await ApiService.instance.get('/portfolio/insight');
    if (res['success'] != true) return '';
    return (res['data'] as Map<String, dynamic>)['insight'] as String? ?? '';
  }
}
