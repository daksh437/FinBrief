import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Caches the raw profile JSON from /auth/bootstrap so a network failure on
// launch degrades to slightly-stale data instead of a hard error screen.
class ProfileCacheService {
  ProfileCacheService._();

  static const _key = 'profile_cache';

  static Future<void> save(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
