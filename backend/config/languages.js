// Languages summaries can be translated into.
//
// Hindi alone reaches roughly 40% of India, and not the part with the deepest
// retail equity participation — Gujarat and Maharashtra do, and read Gujarati
// and Marathi. No large Indian finance app offers either, so this is cheap
// ground to hold: adding a language costs one entry here, because the prompt
// takes the language as a parameter.
//
// `ttsLocale` is what the phone's speech engine expects. Not every device has
// every voice installed; the client falls back to English rather than going
// silent, which would look like a broken feature.
const LANGUAGES = {
  en: { name: 'English', native: 'English', ttsLocale: 'en-IN' },
  hi: { name: 'Hindi', native: 'हिन्दी', ttsLocale: 'hi-IN' },
  gu: { name: 'Gujarati', native: 'ગુજરાતી', ttsLocale: 'gu-IN' },
  mr: { name: 'Marathi', native: 'मराठी', ttsLocale: 'mr-IN' },
  ta: { name: 'Tamil', native: 'தமிழ்', ttsLocale: 'ta-IN' },
  te: { name: 'Telugu', native: 'తెలుగు', ttsLocale: 'te-IN' },
  bn: { name: 'Bengali', native: 'বাংলা', ttsLocale: 'bn-IN' },
  kn: { name: 'Kannada', native: 'ಕನ್ನಡ', ttsLocale: 'kn-IN' },
  ml: { name: 'Malayalam', native: 'മലയാളം', ttsLocale: 'ml-IN' },
  pa: { name: 'Punjabi', native: 'ਪੰਜਾਬੀ', ttsLocale: 'pa-IN' },
};

const DEFAULT_LANGUAGE = 'hi';

/// Resolves a client-supplied code to a supported language.
///
/// Falls back to Hindi rather than erroring: a stale client sending an unknown
/// code should still get a translation, not a failed request.
function resolveLanguage(code) {
  const key = String(code || '').toLowerCase().slice(0, 2);
  return LANGUAGES[key] ? key : DEFAULT_LANGUAGE;
}

const nameOf = (code) => LANGUAGES[resolveLanguage(code)].name;

module.exports = { LANGUAGES, DEFAULT_LANGUAGE, resolveLanguage, nameOf };
