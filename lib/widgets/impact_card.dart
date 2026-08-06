import 'package:flutter/material.dart';
import '../models/ai_summary.dart';
import '../theme/app_spacing.dart';

/// What a story concerns, and which parts of the market it touches.
///
/// The green/red BULLISH/BEARISH chip and its trending arrow are gone, along
/// with the confidence percentage that made a generated opinion look measured.
/// A direction attached to a named security reads as a call regardless of the
/// surrounding wording — see [MarketImpact]. The sector chips and the plain
/// explanation carry the useful half.
class ImpactCard extends StatelessWidget {
  final MarketImpact impact;

  const ImpactCard({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What this affects', style: theme.textTheme.titleSmall),
            if (impact.reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(impact.reason, style: theme.textTheme.bodyMedium),
            ],
            if (impact.affectedSectors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Sectors in the story', style: theme.textTheme.titleSmall),
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
          ],
        ),
      ),
    );
  }
}
