import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_languages.dart';

// Local, device-only flags for one-time setup flows (onboarding intro,
// language/interest pickers). Not synced to the backend — reinstalling the
// app or clearing app data resets these, which is fine for this purpose.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _languageSelectedKey = 'language_selected';
  static const _interestsSelectedKey = 'interests_selected';
  static const _selectedLanguageKey = 'selected_language';
  static const _selectedInterestsKey = 'selected_interests';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  static Future<bool> hasSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  /// The reading language, as an ISO code ('hi', 'gu', 'mr', …).
  ///
  /// Earlier builds stored display names ("English", "Hindi", "Both") because
  /// Hindi was the only option. Those values are translated here rather than
  /// left to fail: an existing install must not lose its choice on upgrade.
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_selectedLanguageKey);
    if (stored == null) return AppLanguages.defaultCode;

    const legacy = {'english': 'en', 'hindi': 'hi', 'both': 'hi'};
    final migrated = legacy[stored.toLowerCase()];
    if (migrated != null) {
      await prefs.setString(_selectedLanguageKey, migrated);
      return migrated;
    }
    return stored;
  }

  /// [languageCode] is an ISO code, not a display name.
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, languageCode);
    await prefs.setBool(_languageSelectedKey, true);
  }

  static Future<bool> hasSelectedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_interestsSelectedKey) ?? false;
  }

  static Future<void> setInterests(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedInterestsKey, interests);
    await prefs.setBool(_interestsSelectedKey, true);
  }
}
