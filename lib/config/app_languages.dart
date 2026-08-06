/// Languages a summary can be translated into.
///
/// Mirrors backend/config/languages.js. Kept as a local list rather than
/// fetched, so the picker works offline and on first launch; the backend is
/// still the authority on what it will actually translate, and resolves an
/// unknown code to Hindi rather than failing.
///
/// Hindi alone reaches roughly 40% of India, and not the part with the deepest
/// retail equity participation — Gujarat and Maharashtra do. No large Indian
/// finance app offers Gujarati or Marathi summaries.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.native,
    required this.ttsLocale,
  });

  final String code;
  final String name;

  /// Shown in the picker in the language's own script — someone looking for
  /// Gujarati is looking for "ગુજરાતી", not for the word "Gujarati".
  final String native;

  /// What the phone's speech engine expects. Not every device has every voice;
  /// SquawkService falls back to English rather than going silent.
  final String ttsLocale;
}

class AppLanguages {
  AppLanguages._();

  static const all = [
    AppLanguage(code: 'en', name: 'English', native: 'English', ttsLocale: 'en-IN'),
    AppLanguage(code: 'hi', name: 'Hindi', native: 'हिन्दी', ttsLocale: 'hi-IN'),
    AppLanguage(code: 'gu', name: 'Gujarati', native: 'ગુજરાતી', ttsLocale: 'gu-IN'),
    AppLanguage(code: 'mr', name: 'Marathi', native: 'मराठी', ttsLocale: 'mr-IN'),
    AppLanguage(code: 'ta', name: 'Tamil', native: 'தமிழ்', ttsLocale: 'ta-IN'),
    AppLanguage(code: 'te', name: 'Telugu', native: 'తెలుగు', ttsLocale: 'te-IN'),
    AppLanguage(code: 'bn', name: 'Bengali', native: 'বাংলা', ttsLocale: 'bn-IN'),
    AppLanguage(code: 'kn', name: 'Kannada', native: 'ಕನ್ನಡ', ttsLocale: 'kn-IN'),
    AppLanguage(code: 'ml', name: 'Malayalam', native: 'മലയാളം', ttsLocale: 'ml-IN'),
    AppLanguage(code: 'pa', name: 'Punjabi', native: 'ਪੰਜਾਬੀ', ttsLocale: 'pa-IN'),
  ];

  static const defaultCode = 'hi';

  static AppLanguage byCode(String? code) {
    return all.firstWhere(
      (l) => l.code == code,
      orElse: () => all.firstWhere((l) => l.code == defaultCode),
    );
  }

  /// Languages offered for translating an article — English is excluded
  /// because the article is already in English.
  static List<AppLanguage> get translationTargets =>
      all.where((l) => l.code != 'en').toList();
}
