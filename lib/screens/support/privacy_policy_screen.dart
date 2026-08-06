import 'package:flutter/material.dart';
import '../../services/legal_service.dart';
import '../../widgets/legal_document.dart';

/// Privacy Policy.
///
/// The text is not held here: it comes from backend/legal/privacy.json, which
/// the backend also serves as a public web page. Google Play requires a
/// policy at a public URL, and having the two rendered from one file keeps
/// them from drifting apart.
///
/// Every claim in that file was checked against what the app actually does.
/// It has NOT been reviewed by a lawyer.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentLoader(assetPath: LegalService.privacyPath, fallbackTitle: 'Privacy Policy');
  }
}
