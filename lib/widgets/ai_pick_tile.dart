import 'package:flutter/material.dart';
import '../models/ai_pick.dart';
import '../theme/app_spacing.dart';

/// A company the day's news is about.
///
/// The coloured BULLISH / BEARISH chip that used to sit here is gone. A green
/// or red badge next to a ticker is read as a call no matter what the caption
/// says — see [AiPick]. The ticker is shown instead, which is information
/// rather than a view.
class AiPickTile extends StatelessWidget {
  final AiPick pick;

  const AiPickTile({super.key, required this.pick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pick.name,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            pick.symbol,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 6),
          Text(
            pick.reason,
            style: theme.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
