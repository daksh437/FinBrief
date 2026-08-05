import 'package:flutter/material.dart';
import '../models/ai_summary.dart';
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

IconData _sentimentIcon(String sentiment) {
  switch (sentiment) {
    case 'bullish':
      return Icons.trending_up;
    case 'bearish':
      return Icons.trending_down;
    default:
      return Icons.trending_flat;
  }
}

class ImpactCard extends StatelessWidget {
  final MarketImpact impact;

  const ImpactCard({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    final color = _sentimentColor(impact.sentiment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Market Impact', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sentimentIcon(impact.sentiment), size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        impact.sentiment.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (impact.reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(impact.reason, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (impact.affectedSectors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Affected sectors', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: impact.affectedSectors
                    .map((s) => Chip(
                          label: Text(s),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            if (impact.confidence > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Confidence: ${(impact.confidence * 100).clamp(0, 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
