import 'package:flutter/material.dart';
import '../models/ai_pick.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

Color _sentimentColor(String sentiment) {
  switch (sentiment) {
    case 'bullish':
      return AppColors.success;
    case 'bearish':
      return AppColors.danger;
    default:
      return AppColors.secondary;
  }
}

class AiPickTile extends StatelessWidget {
  final AiPick pick;

  const AiPickTile({super.key, required this.pick});

  @override
  Widget build(BuildContext context) {
    final color = _sentimentColor(pick.sentiment);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pick.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  pick.sentiment.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pick.reason,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
