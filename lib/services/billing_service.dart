import '../models/purchase_record.dart';
import 'api_service.dart';

// Client-side billing is advisory only — the backend's /billing/verify call
// (which checks the purchase token against Google Play) is what actually
// grants premium/credits. See backend/services/billingService.js.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    return ApiService.instance.post('/billing/verify', body: {
      'productId': productId,
      'purchaseToken': purchaseToken,
    });
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await ApiService.instance.get('/billing/status');
    return res['success'] == true ? res['data'] as Map<String, dynamic> : {'plan': 'free', 'creditBalance': 0};
  }

  Future<List<PurchaseRecord>> getHistory() async {
    final res = await ApiService.instance.get('/billing/history');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((p) => PurchaseRecord.fromJson(p)).toList();
  }
}
