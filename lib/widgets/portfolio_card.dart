import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';
import '../models/quote.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/money.dart';

class PortfolioCard extends StatelessWidget {
  final PortfolioItem item;

  /// Null when the symbol couldn't be resolved — the card then shows the
  /// user's own invested figure and says P/L is unavailable, rather than
  /// inventing a price.
  final Quote? quote;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.item,
    this.quote,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = quote != null;
    // The user typed avgPrice in whatever currency the instrument trades in,
    // so the quote's currency applies to their figures too.
    final currency = quote?.currency;
    final currentValue = hasPrice ? quote!.price * item.quantity : null;
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
                          '${item.quantity} @ ${Money.format(item.avgPrice, currency)}',
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
                  Text(
                    'Invested: ${Money.format(item.investedValue, currency)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (pnl != null)
                    Text(
                      '${Money.formatSigned(pnl, currency)} (${pnlPercent!.toStringAsFixed(1)}%)',
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
