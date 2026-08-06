import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo(size: 64),
            const SizedBox(height: AppSpacing.md),
            Text('FinBrief', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Version 1.0.0'),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'FinBrief is an AI-powered financial intelligence platform delivering real-time '
              'financial news, Hindi translation, AI summaries, market impact analysis, and '
              'portfolio-based alerts — built for India\'s retail investors.',
            ),
          ],
        ),
      ),
    );
  }
}
