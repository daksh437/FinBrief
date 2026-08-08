import '../config/monetization_config.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String plan; // 'free' | 'premium'
  final int aiUsedToday;

  /// Set by a service-account write only — never grantable from the app.
  /// Controls whether the Admin entry is shown; the routes themselves are
  /// gated on the server.
  final bool isAdmin;

  UserProfile({
    required this.uid,
    required this.plan,
    this.email,
    this.aiUsedToday = 0,
    this.isAdmin = false,
  });

  bool get isPremium => plan == 'premium';

  /// Today's ceiling. Advisory only — the server enforces the real limit, and
  /// this exists so the UI can say "2 of 5 used" without another round trip.
  int get dailyLimit =>
      isPremium ? MonetizationConfig.dailyLimitPremium : MonetizationConfig.dailyLimitFree;

  int get aiRemainingToday => (dailyLimit - aiUsedToday).clamp(0, dailyLimit);

  /// Premium's ceiling is a fair-use guard, not a product limit, so it is never
  /// surfaced as a countdown — only free users are shown one.
  bool get showsUsageCounter => !isPremium;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final aiUsage = json['aiUsage'] as Map<String, dynamic>?;
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final usedToday = (aiUsage != null && aiUsage['date'] == today) ? (aiUsage['count'] as num?)?.toInt() ?? 0 : 0;

    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      plan: (json['plan'] as String?) ?? 'free',
      aiUsedToday: usedToday,
      isAdmin: json['isAdmin'] == true,
    );
  }
}
