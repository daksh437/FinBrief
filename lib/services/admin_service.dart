import 'api_service.dart';

/// Admin API client.
///
/// The gate is on the server: these routes return 404 to anyone without the
/// admin flag, so hiding the screen in the app is presentation, not security.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<Map<String, dynamic>?> overview() async {
    final res = await ApiService.instance.get('/admin/overview');
    return res['success'] == true ? res['data'] as Map<String, dynamic> : null;
  }

  Future<List<Map<String, dynamic>>> users() async {
    final res = await ApiService.instance.get('/admin/users');
    if (res['success'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> setPlan(String uid, String plan) async {
    final res = await ApiService.instance.patch('/admin/users/$uid/plan', body: {'plan': plan});
    return res['success'] == true;
  }

  Future<List<Map<String, dynamic>>> errors() async {
    final res = await ApiService.instance.get('/admin/errors');
    if (res['success'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> feedback() async {
    final res = await ApiService.instance.get('/admin/feedback');
    if (res['success'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }
}
