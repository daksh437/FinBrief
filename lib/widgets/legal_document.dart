import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A titled block of legal copy.
class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// Shared layout for the Privacy Policy and Terms screens so both stay
/// visually and structurally consistent, and so the "last updated" line is
/// rendered the same way in each.
class LegalDocument extends StatelessWidget {
  const LegalDocument({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(intro, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          for (final section in sections) ...[
            Text(section.heading, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(section.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
