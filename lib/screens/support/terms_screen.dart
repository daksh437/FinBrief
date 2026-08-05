import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder draft — needs real legal review before this app is published.
            Text(
              'This is a placeholder terms of service and has not been reviewed by legal counsel. '
              'Replace this content with real, reviewed terms before publishing FinBrief.\n\n'
              'FinBrief provides financial news, AI-generated summaries and translations, and market '
              'information for general informational purposes only. Nothing in the app is financial, '
              'investment, or legal advice. Market data and AI-generated insights may be inaccurate, '
              'delayed, or unavailable. You are responsible for your own investment decisions.',
            ),
          ],
        ),
      ),
    );
  }
}
