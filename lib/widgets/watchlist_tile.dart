import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/watchlist_item.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

class WatchlistTile extends StatelessWidget {
  final WatchlistItem item;

  /// Null when the symbol couldn't be resolved. The tile then shows no price
  /// rather than a made-up one.
  final Quote? quote;
  final VoidCallback onRemove;

  const WatchlistTile({
    super.key,
    required this.item,
    required this.onRemove,
    this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final up = (quote?.changePercent ?? 0) >= 0;

    return Dismissible(
      key: ValueKey(item.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        title: Text(item.symbol),
        subtitle: item.alertPrice != null
            // The alert price is the user's own figure, so it carries the same
            // currency as the instrument.
            ? Text('Alert at ${Money.format(item.alertPrice, quote?.currency)}')
            : null,
        trailing: quote != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(quote!.price, quote!.currency),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${up ? '+' : ''}${(quote!.changePercent ?? 0).toStringAsFixed(2)}%',
                    style: TextStyle(color: up ? AppColors.success : AppColors.danger, fontSize: 12),
                  ),
                ],
              )
            : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
      ),
    );
  }
}
