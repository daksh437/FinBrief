import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder draft — needs real legal review before this app is published.
            Text(
              'This is a placeholder privacy policy and has not been reviewed by legal counsel. '
              'Replace this content with a real, reviewed privacy policy before publishing FinBrief.\n\n'
              'FinBrief collects: your email (for authentication), Firebase-issued identifiers, '
              'app usage such as AI feature usage counts and bookmarked/watched articles, and — if you '
              'grant permission — a device push-notification token. This data is used to provide the '
              'app\'s core features (news, AI summaries, watchlist/portfolio, alerts) and is not sold to '
              'third parties.',
            ),
          ],
        ),
      ),
    );
  }
}
