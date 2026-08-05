import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice squawk — reads new headlines aloud, FinancialJuice-style.
///
/// Uses the phone's built-in TTS engine rather than a cloud API, so it costs
/// nothing, has no quota, and works offline. (The server-side
/// `/ai/voice-summary` endpoint still exists for the article-detail "Listen"
/// button, which reads full AI summaries; this is for the rapid headline tape.)
class SquawkService {
  SquawkService._();
  static final SquawkService instance = SquawkService._();

  static const _enabledKey = 'squawk_enabled';
  static const _langKey = 'squawk_language';

  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;
  bool _enabled = false;
  String _language = 'en-IN';

  /// Headlines already spoken, so a feed refresh doesn't repeat them.
  final Set<String> _spoken = {};

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_initialised) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;

    await _tts.setSpeechRate(0.5); // default is fast enough to be unclear
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _applyLanguage(prefs.getString(_langKey) ?? 'en-IN');

    _initialised = true;
  }

  Future<void> _applyLanguage(String code) async {
    try {
      final available = await _tts.isLanguageAvailable(code);
      // Fall back to English if the device has no Hindi voice installed —
      // silence would look like the feature is broken.
      _language = available == true ? code : 'en-IN';
      await _tts.setLanguage(_language);
    } catch (_) {
      _language = 'en-IN';
      await _tts.setLanguage(_language);
    }
  }

  Future<void> setLanguage(String code) async {
    await init();
    await _applyLanguage(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  Future<void> setEnabled(bool value) async {
    await init();
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) await stop();
  }

  /// Speaks [text] once. No-op when squawk is off.
  Future<void> speak(String text) async {
    await init();
    if (!_enabled || text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  /// Announces a headline, skipping anything already read out.
  /// [impact] is spoken too, since that's the part users actually care about.
  Future<void> announce({required String id, required String headline, String? impact}) async {
    await init();
    if (!_enabled || _spoken.contains(id)) return;
    _spoken.add(id);

    final line = impact == null || impact.isEmpty ? headline : '$headline. Impact: $impact';
    await _tts.speak(line);
  }

  /// Reads [text] aloud on demand — used by the article "Listen" button.
  ///
  /// Unlike [speak]/[announce] this ignores the squawk toggle, since the user
  /// pressing Listen *is* the request. The returned future completes when the
  /// engine finishes speaking (see `awaitSpeakCompletion` in [init]), so the
  /// caller can reset its play state without polling.
  ///
  /// Deliberately on-device: the server-side TTS endpoint needs a paid Google
  /// Cloud key, and without one it returns placeholder bytes that play as
  /// silence. This costs nothing and works offline.
  Future<void> readAloud(String text, {String? languageCode}) async {
    await init();
    if (text.trim().isEmpty) return;

    final previous = _language;
    if (languageCode != null && languageCode != previous) {
      await _applyLanguage(languageCode);
    }

    await _tts.stop();
    try {
      await _tts.speak(text);
    } finally {
      if (_language != previous) await _applyLanguage(previous);
    }
  }

  Future<void> stop() async => _tts.stop();

  /// Lets a fresh session re-announce headlines (e.g. after sign-out).
  void resetSpokenHistory() => _spoken.clear();
}
