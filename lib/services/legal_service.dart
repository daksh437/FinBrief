import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/legal_document.dart';

/// Loads the Privacy Policy and Terms.
///
/// The JSON is the same file the backend renders at /privacy and /terms, so
/// the in-app screen and the publicly hosted page can never say different
/// things. Bundled as an asset rather than fetched, so the policy is readable
/// offline and without an account.
class LegalService {
  LegalService._();

  static const privacyPath = 'backend/legal/privacy.json';
  static const termsPath = 'backend/legal/terms.json';

  /// Public URLs for the same documents — used where a link is needed rather
  /// than a screen (Play Store listing, external references).
  static const privacyUrl = 'https://finbrief-backend.onrender.com/privacy';
  static const termsUrl = 'https://finbrief-backend.onrender.com/terms';

  static final Map<String, LegalContent> _cache = {};

  static Future<LegalContent> load(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final json = jsonDecode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>;
    final content = LegalContent(
      title: json['title'] as String,
      lastUpdated: json['lastUpdated'] as String,
      intro: json['intro'] as String,
      sections: (json['sections'] as List)
          .map((s) => LegalSection(s['heading'] as String, s['body'] as String))
          .toList(),
    );

    _cache[assetPath] = content;
    return content;
  }
}

class LegalContent {
  const LegalContent({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;
}
