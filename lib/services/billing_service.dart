import '../models/purchase_record.dart';
import 'api_service.dart';

// Client-side billing is advisory only — the backend's /billing/verify call
// (which checks the purchase token against Google Play) is what actually
// grants premium. See backend/services/billingService.js.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String? basePlan,
  }) async {
    return ApiService.instance.post('/billing/verify', body: {
      'productId': productId,
      'purchaseToken': purchaseToken,
      // Which billing period was bought — recorded so renewals and churn can
      // be compared per period later.
      'basePlan': basePlan,
    });
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await ApiService.instance.get('/billing/status');
    // Falling back to 'free' on failure is deliberate: a network error must
    // never hand out Premium.
    return res['success'] == true ? res['data'] as Map<String, dynamic> : {'plan': 'free'};
  }

  Future<List<PurchaseRecord>> getHistory() async {
    final res = await ApiService.instance.get('/billing/history');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((p) => PurchaseRecord.fromJson(p)).toList();
  }
}
