import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../models/ai_summary.dart';
import 'api_service.dart';

class AiInsufficientCreditsException implements Exception {}

class VoiceSummaryResult {
  final String summary;
  final Uint8List audioBytes;
  VoiceSummaryResult({required this.summary, required this.audioBytes});
}

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final _random = Random.secure();

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<T> _call<T>(String path, Map<String, dynamic> body, T Function(Map<String, dynamic> data) parse) async {
    final res = await ApiService.instance.post(path, body: body, idempotencyKey: _newIdempotencyKey());

    if (res['error'] == 'INSUFFICIENT_CREDITS') {
      throw AiInsufficientCreditsException();
    }
    if (res['success'] != true) {
      // Prefer ApiService's friendly `message` (timeout/network/server) so
      // screens can surface it directly instead of a raw error code.
      throw Exception(res['message'] ?? res['error'] ?? 'AI request failed');
    }
    return parse(res['data'] as Map<String, dynamic>);
  }

  Future<String> translateToHindi(String text) {
    return _call('/ai/translate', {'text': text}, (d) => d['translated'] as String);
  }

  Future<String> summarize(String text) {
    return _call('/ai/summary', {'text': text}, (d) => d['summary'] as String);
  }

  /// Full summary payload including key points and a confidence score.
  Future<AiSummary> summarizeStructured(String text) {
    return _call('/ai/summary', {'text': text}, AiSummary.fromJson);
  }

  Future<MarketImpact> analyzeMarketImpact(String text) {
    return _call('/ai/impact', {'text': text}, MarketImpact.fromJson);
  }

  Future<Map<String, dynamic>> analyzeImpact(String text) {
    return _call('/ai/impact', {'text': text}, (d) => d);
  }

  /// [mode] is one of: why-it-matters, future-impact, beginner, hindi.
  Future<String> explain(String text, String mode) {
    return _call('/ai/explain', {'text': text, 'mode': mode}, (d) => d['explanation'] as String);
  }

  Future<String> chat(List<Map<String, String>> messages) {
    return _call('/ai/chat', {'messages': messages}, (d) => d['reply'] as String);
  }

  Future<VoiceSummaryResult> voiceSummary(String text, {String languageCode = 'en-IN'}) {
    return _call(
      '/ai/voice-summary',
      {'text': text, 'languageCode': languageCode},
      (d) => VoiceSummaryResult(
        summary: d['summary'] as String,
        audioBytes: base64Decode(d['audioContent'] as String),
      ),
    );
  }
}
