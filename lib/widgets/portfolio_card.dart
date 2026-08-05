import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final double? currentPrice;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.item,
    this.currentPrice,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = currentPrice != null;
    final currentValue = hasPrice ? currentPrice! * item.quantity : null;
    final pnl = hasPrice ? currentValue! - item.investedValue : null;
    final pnlPercent = hasPrice && item.investedValue > 0 ? (pnl! / item.investedValue) * 100 : null;
    final pnlColor = (pnl ?? 0) >= 0 ? AppColors.success : AppColors.danger;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.symbol, style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          '${item.quantity} @ ₹${item.avgPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onRemove,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invested: ₹${item.investedValue.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                  if (pnl != null)
                    Text(
                      '${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(2)} (${pnlPercent!.toStringAsFixed(1)}%)',
                      style: TextStyle(color: pnlColor, fontWeight: FontWeight.w600, fontSize: 12),
                    )
                  else
                    const Text('P/L unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
