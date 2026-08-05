import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ProfileHeader extends StatelessWidget {
  final String? email;
  final String plan;

  const ProfileHeader({super.key, required this.email, required this.plan});

  @override
  Widget build(BuildContext context) {
    final initial = (email?.isNotEmpty ?? false) ? email![0].toUpperCase() : '?';
    final isPremium = plan == 'premium';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary,
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email ?? 'Signed in', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPremium ? AppColors.success : AppColors.secondary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPremium ? 'PREMIUM' : 'FREE',
                    style: TextStyle(
                      color: isPremium ? AppColors.success : AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
