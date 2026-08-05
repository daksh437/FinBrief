import 'package:flutter/material.dart';
import '../models/market_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MarketTile extends StatelessWidget {
  final MarketItem item;

  const MarketTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final changeColor = item.isUp ? AppColors.success : AppColors.danger;
    final sign = item.isUp ? '+' : '';

    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$sign${item.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(color: changeColor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
