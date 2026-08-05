class UserProfile {
  final String uid;
  final String? email;
  final String plan; // 'free' | 'premium'
  final int creditBalance;
  final DateTime? trialStartedAt;
  final int aiUsedToday;

  UserProfile({
    required this.uid,
    required this.plan,
    this.email,
    this.creditBalance = 0,
    this.trialStartedAt,
    this.aiUsedToday = 0,
  });

  bool get isPremium => plan == 'premium';

  bool get isInTrial {
    if (trialStartedAt == null) return false;
    return DateTime.now().difference(trialStartedAt!).inDays < 7;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final aiUsage = json['aiUsage'] as Map<String, dynamic>?;
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final usedToday = (aiUsage != null && aiUsage['date'] == today) ? (aiUsage['count'] as num?)?.toInt() ?? 0 : 0;

    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      plan: (json['plan'] as String?) ?? 'free',
      creditBalance: (json['creditBalance'] as num?)?.toInt() ?? 0,
      trialStartedAt: json['trialStartedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['trialStartedAt'] as int)
          : null,
      aiUsedToday: usedToday,
    );
  }
}
