import 'package:flutter/material.dart';
import '../../models/watchlist_item.dart';
import '../../services/market_service.dart';
import '../../services/watchlist_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/watchlist_tile.dart';

const _types = ['Stocks', 'Crypto', 'Gold', 'Forex'];

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Future<List<WatchlistItem>> _itemsFuture;
  Map<String, double> _quotes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _itemsFuture = WatchlistService.instance.list().then((items) async {
      if (items.isNotEmpty) {
        final quotes = await MarketService.instance.getQuotes(items.map((i) => i.symbol).toList());
        if (mounted) setState(() => _quotes = quotes);
      }
      return items;
    });
  }

  Future<void> _addSymbolDialog() async {
    final controller = TextEditingController();
    String selectedType = _types.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add to watchlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'e.g. RELIANCE, BTC, XAU'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {'symbol': controller.text, 'type': selectedType}),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['symbol']!.trim().isNotEmpty) {
      await WatchlistService.instance.add(result['symbol']!.trim(), type: result['type']!);
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [IconButton(onPressed: _addSymbolDialog, icon: const Icon(Icons.add))],
      ),
      body: FutureBuilder<List<WatchlistItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(message: 'Add tickers to get portfolio alerts.', icon: Icons.show_chart);
          }

          final grouped = <String, List<WatchlistItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.type, () => []).add(item);
          }

          return ListView(
            children: _types.where((t) => grouped.containsKey(t)).expand((type) {
              final groupItems = grouped[type]!;
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                  child: Text(type, style: Theme.of(context).textTheme.titleLarge),
                ),
                ...groupItems.map(
                  (item) => WatchlistTile(
                    item: item,
                    currentPrice: _quotes[item.symbol],
                    onRemove: () async {
                      await WatchlistService.instance.remove(item.symbol);
                      setState(_load);
                    },
                  ),
                ),
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}
