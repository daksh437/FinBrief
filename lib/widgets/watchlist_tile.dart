import 'package:flutter/material.dart';
import '../models/watchlist_item.dart';
import '../theme/app_colors.dart';

class WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  final double? currentPrice;
  final double? changePercent;
  final VoidCallback onRemove;

  const WatchlistTile({
    super.key,
    required this.item,
    required this.onRemove,
    this.currentPrice,
    this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final up = (changePercent ?? 0) >= 0;

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
        subtitle: item.alertPrice != null ? Text('Alert at ${item.alertPrice}') : null,
        trailing: currentPrice != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currentPrice!.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${up ? '+' : ''}${(changePercent ?? 0).toStringAsFixed(2)}%',
                    style: TextStyle(color: up ? AppColors.success : AppColors.danger, fontSize: 12),
                  ),
                ],
              )
            : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
      ),
    );
  }
}
