/// Pricing and limits, mirrored from the server.
///
/// The server is authoritative for the limits — these copies only drive UI
/// copy so the app can say "5 a day" without a round trip. Never enforce
/// anything from here.
class MonetizationConfig {
  MonetizationConfig._();

  static const int dailyLimitFree = 5;

  /// Premium is sold as unlimited but carries a fair-use ceiling. At ₹999/year
  /// the net is roughly ₹85/month, and 100 AI calls a day would cost more than
  /// that in Gemini usage, so this stops one runaway account from turning a
  /// subscriber into a loss. Normal use is 10-15 a day and never sees it.
  static const int dailyLimitPremium = 100;

  /// One subscription in Play Console with three base plans hanging off it,
  /// rather than three separate products — that way a user can switch period
  /// without cancelling, and Play itself limits the intro offer to first-time
  /// subscribers.
  static const String subscriptionId = 'finbrief_premium';

  static const List<PremiumPlan> plans = [
    PremiumPlan(
      basePlanId: 'yearly',
      label: 'Yearly',
      priceLabel: '₹999',
      perMonthLabel: '₹83/month',
      savingLabel: 'Save 58%',
      isBestValue: true,
    ),
    PremiumPlan(
      basePlanId: 'six-month',
      label: '6 months',
      priceLabel: '₹899',
      perMonthLabel: '₹150/month',
      savingLabel: 'Save 25%',
    ),
    PremiumPlan(
      basePlanId: 'monthly',
      label: 'Monthly',
      priceLabel: '₹199',
      perMonthLabel: '₹199/month',
      introPriceLabel: '₹49',
      // Play requires the renewal price to be as prominent as the offer price.
      // Burying it is both a policy problem and how you earn chargebacks.
      introTermsLabel: '₹49 for your first month, then ₹199/month. Cancel anytime.',
    ),
  ];

  static PremiumPlan get defaultPlan => plans.firstWhere((p) => p.isBestValue);
}

class PremiumPlan {
  const PremiumPlan({
    required this.basePlanId,
    required this.label,
    required this.priceLabel,
    required this.perMonthLabel,
    this.savingLabel,
    this.isBestValue = false,
    this.introPriceLabel,
    this.introTermsLabel,
  });

  final String basePlanId;
  final String label;
  final String priceLabel;
  final String perMonthLabel;
  final String? savingLabel;
  final bool isBestValue;

  /// Set only where Play has an introductory offer attached. The app shows it
  /// but never assumes the user is eligible — Play decides that, and a
  /// returning subscriber is charged the normal price.
  final String? introPriceLabel;
  final String? introTermsLabel;

  bool get hasIntroOffer => introPriceLabel != null;
}
