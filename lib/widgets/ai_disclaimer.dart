import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Standing notice that AI output can be wrong and that nothing in the app is
/// investment advice.
///
/// This is deliberately a shared widget rather than copy pasted per screen:
/// the wording is a compliance surface, so it has to change in exactly one
/// place. Shown wherever generated content appears — article summaries, market
/// impact, chat, and the Home screen's AI sections.
class AiDisclaimer extends StatelessWidget {
  const AiDisclaimer({super.key, this.compact = false});

  /// Single line, for dense screens like the Home feed.
  final bool compact;

  static const String text =
      'AI-generated and may be inaccurate. Information only — not investment advice. '
      'Verify before acting and consider consulting a SEBI-registered adviser.';

  static const String textCompact = 'AI-generated, may be inaccurate. Not investment advice.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.35,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(compact ? textCompact : text, style: style)),
        ],
      ),
    );
  }
}
