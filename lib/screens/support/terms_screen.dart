import 'package:flutter/material.dart';
import '../../services/legal_service.dart';
import '../../widgets/legal_document.dart';

/// Terms of Service.
///
/// Text lives in backend/legal/terms.json, shared with the public page the
/// backend serves at /terms — see [PrivacyPolicyScreen] for why.
///
/// The "not investment advice" section is the important one and is written to
/// match what the app actually shows. It has NOT been reviewed by a lawyer,
/// and an app that comments on specific securities to Indian users should be
/// checked against SEBI's investment-adviser and research-analyst regulations
/// before release.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentLoader(assetPath: LegalService.termsPath, fallbackTitle: 'Terms of Service');
  }
}
