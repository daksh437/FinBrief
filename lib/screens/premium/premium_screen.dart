import 'package:flutter/material.dart';
import '../../config/monetization_config.dart';
import '../../models/purchase_record.dart';
import '../../services/billing_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/plan_card.dart';

/// The paywall.
///
/// One subscription, three billing periods. There is no free trial and no
/// credit packs: a ₹49 first month replaces the trial (it leaves a card on
/// file and renews, where a free trial mostly spends AI quota on people who
/// were never going to pay), and a second way to pay only split the decision.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Map<String, dynamic>? _status;
  late Future<List<PurchaseRecord>> _history;

  // Yearly is preselected because it is the plan we want people on — paid up
  // front, far less churn — and most users take whatever is already chosen.
  String _selectedPlanId = MonetizationConfig.defaultPlan.basePlanId;

  @override
  void initState() {
    super.initState();
    BillingService.instance.getStatus().then((s) {
      if (mounted) setState(() => _status = s);
    });
    _history = BillingService.instance.getHistory();
  }

  bool get _isPremium => _status?['plan'] == 'premium';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = MonetizationConfig.plans.firstWhere((p) => p.basePlanId == _selectedPlanId);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_isPremium) _activeBanner(theme) else ..._offer(theme, selected),
          const SizedBox(height: AppSpacing.lg * 2),
          Text('Purchase history', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _historyList(),
        ],
      ),
    );
  }

  Widget _activeBanner(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium is active', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Manage or cancel your subscription in the Google Play Store.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _offer(ThemeData theme, PremiumPlan selected) {
    return [
      Text('Go Premium', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Free gives you ${MonetizationConfig.dailyLimitFree} AI actions a day. '
        'Premium removes the limit and the ads.',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.lg),

      const _Benefit(icon: Icons.auto_awesome, text: 'Unlimited AI summaries, Hindi translation and market impact'),
      const _Benefit(icon: Icons.block, text: 'No ads, anywhere in the app'),
      const _Benefit(icon: Icons.notifications_active_outlined, text: 'All breaking alerts plus morning and evening briefs'),
      const _Benefit(icon: Icons.account_balance_wallet_outlined, text: 'Unlimited portfolio holdings and linked news'),

      const SizedBox(height: AppSpacing.lg),
      Text('Choose a plan', style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),

      for (final plan in MonetizationConfig.plans) ...[
        PlanCard(
          name: plan.label,
          price: plan.hasIntroOffer ? '${plan.introPriceLabel} first month' : plan.priceLabel,
          subtitle: plan.hasIntroOffer ? 'then ${plan.perMonthLabel}' : plan.perMonthLabel,
          badge: plan.savingLabel,
          highlighted: plan.isBestValue,
          isCurrent: plan.basePlanId == _selectedPlanId,
          onPressed: () => setState(() => _selectedPlanId = plan.basePlanId),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],

      const SizedBox(height: AppSpacing.sm),
      FilledButton(
        onPressed: () => _subscribe(selected),
        child: Text(selected.hasIntroOffer
            ? 'Start for ${selected.introPriceLabel}'
            : 'Subscribe — ${selected.priceLabel}'),
      ),
      const SizedBox(height: AppSpacing.sm),

      // Play policy: the renewal price must be disclosed as clearly as the
      // offer price. This line is also what stops "I thought it was ₹49"
      // chargebacks.
      Text(
        selected.introTermsLabel ??
            '${selected.priceLabel} billed ${selected.label.toLowerCase()}. Renews automatically. Cancel anytime in Google Play.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Future<void> _subscribe(PremiumPlan plan) async {
    // TODO: launch the in_app_purchase flow for
    // MonetizationConfig.subscriptionId with plan.basePlanId, then hand the
    // purchase token to BillingService.verifyPurchase and push
    // SubscriptionSuccessScreen. Play Console products must exist first.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchases are not available yet.')),
    );
  }

  Widget _historyList() {
    return FutureBuilder<List<PurchaseRecord>>(
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
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(r.productId),
              subtitle: Text('${date.day}/${date.month}/${date.year}'),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
