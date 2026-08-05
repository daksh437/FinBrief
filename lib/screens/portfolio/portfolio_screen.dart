import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../models/portfolio_item.dart';
import '../../services/market_service.dart';
import '../../services/news_service.dart';
import '../../services/portfolio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/news_card.dart';
import '../../widgets/portfolio_card.dart';
import '../news/article_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<PortfolioItem>> _itemsFuture;
  Map<String, double> _quotes = {};
  String? _insight;
  List<NewsArticle> _relatedNews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _itemsFuture = PortfolioService.instance.list().then((items) async {
      if (items.isNotEmpty) {
        final quotes = await MarketService.instance.getQuotes(items.map((i) => i.symbol).toList());
        final insight = await PortfolioService.instance.getInsight();
        final top = items.reduce((a, b) => a.investedValue > b.investedValue ? a : b);
        final related = await NewsService.instance.search(top.name ?? top.symbol);
        if (mounted) {
          setState(() {
            _quotes = quotes;
            _insight = insight;
            _relatedNews = related.take(3).toList();
          });
        }
      }
      return items;
    });
  }

  Future<void> _addHoldingDialog() async {
    final symbolController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add holding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Symbol (e.g. TCS)'),
            ),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Average buy price'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    final quantity = double.tryParse(qtyController.text);
    final avgPrice = double.tryParse(priceController.text);
    if (confirmed == true && symbolController.text.trim().isNotEmpty && quantity != null && avgPrice != null) {
      await PortfolioService.instance.add(symbolController.text.trim(), quantity: quantity, avgPrice: avgPrice);
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [IconButton(onPressed: _addHoldingDialog, icon: const Icon(Icons.add))],
      ),
      body: FutureBuilder<List<PortfolioItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              message: 'Add your holdings to track your portfolio value.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }

          final totalInvested = items.fold<double>(0, (sum, i) => sum + i.investedValue);
          final totalCurrent = items.fold<double>(
            0,
            (sum, i) => sum + (_quotes[i.symbol] != null ? _quotes[i.symbol]! * i.quantity : i.investedValue),
          );
          final totalPnl = totalCurrent - totalInvested;
          final pnlColor = totalPnl >= 0 ? AppColors.success : AppColors.danger;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Invested'),
                          Text('₹${totalInvested.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Value'),
                          Text('₹${totalCurrent.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overall P/L'),
                          Text(
                            '${totalPnl >= 0 ? '+' : ''}₹${totalPnl.toStringAsFixed(2)}',
                            style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_insight != null) ...[
                const SizedBox(height: AppSpacing.md),
                AIInsightCard(insight: _insight!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Allocation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((item) {
                final value = _quotes[item.symbol] != null ? _quotes[item.symbol]! * item.quantity : item.investedValue;
                final percent = totalCurrent > 0 ? (value / totalCurrent) * 100 : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.symbol),
                          Text('${percent.toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: percent / 100, minHeight: 6),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              Text('Holdings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PortfolioCard(
                      item: item,
                      currentPrice: _quotes[item.symbol],
                      onRemove: () async {
                        await PortfolioService.instance.remove(item.symbol);
                        setState(_load);
                      },
                    ),
                  )),
              if (_relatedNews.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Related News', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ..._relatedNews.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: NewsCard(
                        article: a,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
