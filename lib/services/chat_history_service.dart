import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryService {
  ChatHistoryService._();

  static const _key = 'ai_chat_history';
  static const _maxMessages = 100;

  static Future<List<Map<String, String>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>().map((m) => m.cast<String, String>()).toList();
  }

  static Future<void> save(List<Map<String, String>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = messages.length > _maxMessages ? messages.sublist(messages.length - _maxMessages) : messages;
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
