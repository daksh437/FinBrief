import 'package:flutter/material.dart';
import '../../models/purchase_record.dart';
import '../../services/billing_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/credit_card_tile.dart';
import '../../widgets/plan_card.dart';

// Lite and Pro currently grant identical backend entitlements (both map to
// `plan: premium`) — see [[finance-app-brd]] memory: the 3-tier UI was built
// ahead of any real feature-split decision. Don't invent fake restrictions
// for Lite; both cards list the same real benefits, differing only in
// billing cadence, until a real tier-entitlement decision is made.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Map<String, dynamic>? _status;
  late Future<List<PurchaseRecord>> _history;

  @override
  void initState() {
    super.initState();
    BillingService.instance.getStatus().then((s) => setState(() => _status = s));
    _history = BillingService.instance.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _status?['plan'] ?? '...';
    final credits = _status?['creditBalance'] ?? 0;
    final isPremium = plan == 'premium';

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: ListTile(
              title: Text('Current plan: $plan'),
              subtitle: Text('Credit balance: $credits'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Choose your plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          PlanCard(
            name: 'Free',
            price: '7-day trial, then limited daily AI',
            features: const ['A few AI translations/summaries per day', 'Ads shown', 'All news & watchlist features'],
            isCurrent: !isPremium,
          ),
          const SizedBox(height: AppSpacing.sm),
          PlanCard(
            name: 'Premium Lite',
            price: 'Billed monthly — see Play Store for price',
            features: const ['Unlimited AI translate/summary/chat', 'No ads', 'WhatsApp alerts'],
            isCurrent: isPremium,
            // TODO: wire real in_app_purchase flow (MonetizationConfig.premiumMonthlySubscriptionId),
            // then call BillingService.instance.verifyPurchase(...) and push SubscriptionSuccessScreen.
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.sm),
          PlanCard(
            name: 'Premium Pro',
            price: 'Billed yearly — see Play Store for price',
            features: const ['Unlimited AI translate/summary/chat', 'No ads', 'WhatsApp alerts', 'Priority support'],
            highlighted: true,
            isCurrent: isPremium,
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Credit Packs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const CreditCardTile(label: 'Small Pack', credits: 50, price: 'See Play Store', onPressed: null),
          const SizedBox(height: AppSpacing.sm),
          const CreditCardTile(label: 'Large Pack', credits: 150, price: 'See Play Store', onPressed: null),
          const SizedBox(height: AppSpacing.lg),
          Text('Purchase History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<PurchaseRecord>>(
            future: _history,
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No purchases yet.'),
                );
              }
              return Column(
                children: records.map((r) {
                  final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(r.type == 'subscription' ? Icons.workspace_premium_outlined : Icons.bolt_rounded),
                    title: Text(r.productId),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    trailing: r.creditsGranted != null ? Text('+${r.creditsGranted} credits') : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
