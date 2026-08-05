import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_item.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<List<NotificationItem>> getInbox() async {
    final res = await ApiService.instance.get('/notifications/inbox');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((n) => NotificationItem.fromJson(n)).toList();
  }

  Future<void> registerToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token == null) return;
    await ApiService.instance.post('/notifications/token', body: {'fcmToken': token});
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final res = await ApiService.instance.get('/notifications/preferences');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : {'pushAlerts': true, 'morningBrief': true, 'eveningSummary': true, 'premiumAlerts': false, 'whatsapp': false};
  }

  Future<bool> updatePreferences({
    bool? pushAlerts,
    bool? morningBrief,
    bool? eveningSummary,
    bool? premiumAlerts,
    bool? whatsapp,
  }) async {
    final res = await ApiService.instance.patch('/notifications/preferences', body: {
      'pushAlerts': pushAlerts,
      'morningBrief': morningBrief,
      'eveningSummary': eveningSummary,
      'premiumAlerts': premiumAlerts,
      'whatsapp': whatsapp,
    });
    return res['success'] == true;
  }
}
