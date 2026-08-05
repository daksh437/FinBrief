import 'api_service.dart';

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  /// [type] is 'feedback' or 'bug' so reports can be triaged separately.
  Future<bool> submit(String message, {String type = 'feedback'}) async {
    final res = await ApiService.instance.post('/feedback', body: {
      'message': message,
      'type': type,
    });
    return res['success'] == true;
  }
}
