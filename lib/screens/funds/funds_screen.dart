import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/fund.dart';
import '../../services/funds_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/money.dart';
import '../../widgets/empty_state.dart';
import 'fund_search_screen.dart';

/// The user's mutual funds.
///
/// Most Indian retail money is here rather than in direct equity, so this is
/// the screen that makes the app relevant to the majority of people it is
/// aimed at.
class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  late Future<List<Fund>> _future;

  @override
  void initState() {
    super.initState();
    _future = FundsService.instance.list();
  }

  void _reload() => setState(() => _future = FundsService.instance.list());

  Future<void> _addFund() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FundSearchScreen()),
    );
    if (added == true) _reload();
  }

  Future<void> _remove(Fund fund) async {
    await FundsService.instance.remove(fund.schemeCode);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Funds'),
        actions: [IconButton(onPressed: _addFund, icon: const Icon(Icons.add))],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Fund>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final funds = snapshot.data ?? [];
            if (funds.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    message: 'Add your mutual funds to track their value and get news that affects them.',
                    icon: Icons.pie_chart_outline,
                  ),
                ],
              );
            }

            // Totals are safe here in a way the stock portfolio's aren't: every
            // Indian mutual fund is priced in rupees.
            final invested = funds.fold<double>(0, (sum, f) => sum + (f.invested ?? 0));
            final current = funds.fold<double>(
              0,
              (sum, f) => sum + (f.currentValue ?? f.invested ?? 0),
            );
            final gain = current - invested;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (invested > 0) _summary(context, invested, current, gain),
                const SizedBox(height: AppSpacing.md),
                ...funds.map((f) => _FundCard(fund: f, onRemove: () => _remove(f))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, double invested, double current, double gain) {
    final up = gain >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invested'),
                Text(Money.format(invested, 'INR'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current value'),
                Text(Money.format(current, 'INR'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall gain'),
                Text(
                  '${Money.formatSigned(gain, 'INR')} '
                  '(${invested > 0 ? (gain / invested * 100).toStringAsFixed(1) : '0.0'}%)',
                  style: TextStyle(
                    color: up ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.fund, required this.onRemove});

  final Fund fund;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fund.shortName, style: theme.textTheme.titleSmall),
                      if (fund.planLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          fund.planLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ],
                  ),
                ),
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
                // The NAV date is shown because it is usually yesterday's —
                // funds are valued once a day after markets close, and a user
                // comparing this to a live stock price should know why it
                // hasn't moved.
                Text(
                  fund.nav != null
                      ? 'NAV ${Money.format(fund.nav, 'INR')}${fund.navDate != null ? ' · ${fund.navDate}' : ''}'
                      : 'NAV unavailable',
                  style: theme.textTheme.bodySmall,
                ),
                if (fund.gain != null)
                  Text(
                    '${Money.formatSigned(fund.gain, 'INR')}'
                    '${fund.gainPercent != null ? ' (${fund.gainPercent!.toStringAsFixed(1)}%)' : ''}',
                    style: TextStyle(
                      color: fund.isUp ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (fund.units != null) ...[
              const SizedBox(height: 4),
              Text(
                '${fund.units} units'
                '${fund.currentValue != null ? ' · worth ${Money.format(fund.currentValue, 'INR')}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
