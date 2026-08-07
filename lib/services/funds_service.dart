import '../models/fund.dart';
import 'api_service.dart';

class FundsService {
  FundsService._();
  static final FundsService instance = FundsService._();

  /// Scheme search. The backend needs at least 3 characters and resolves old
  /// fund names ("SBI Bluechip" → "SBI Large Cap"), so short or outdated
  /// queries are its problem, not the caller's.
  Future<List<Fund>> search(String query) async {
    if (query.trim().length < 3) return [];
    final res = await ApiService.instance.get('/funds/search', query: {'q': query});
    if (res['success'] != true) return [];
    return (res['data'] as List).map((f) => Fund.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<List<Fund>> list() async {
    final res = await ApiService.instance.get('/funds');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((f) => Fund.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<bool> add(Fund fund, {double? units, double? invested}) async {
    final res = await ApiService.instance.post('/funds', body: {
      'schemeCode': fund.schemeCode,
      'name': fund.name,
      'units': units,
      'invested': invested,
    });
    return res['success'] == true;
  }

  Future<bool> remove(String schemeCode) async {
    final res = await ApiService.instance.delete('/funds/$schemeCode');
    return res['success'] == true;
  }
}
