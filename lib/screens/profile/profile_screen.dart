import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/monetization_config.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/profile_header.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../bookmarks/history_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final profile = context.watch<UserProvider>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ProfileHeader(email: user?.email, plan: profile?.plan ?? 'free'),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Usage', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      if (profile.isPremium)
                        const Text('Unlimited (Premium)')
                      else if (profile.isInTrial)
                        const Text('Unlimited (Trial)')
                      else
                        Text('${profile.aiUsedToday} / ${MonetizationConfig.dailyCreditsFree} used today'),
                      if (profile.creditBalance > 0) ...[
                        const SizedBox(height: 4),
                        Text('Credit balance: ${profile.creditBalance}'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portfolio',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PortfolioScreen())),
          ),
          SettingsTile(
            icon: Icons.bookmark_outline,
            title: 'Bookmarks',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          SettingsTile(
            icon: Icons.history,
            title: 'Reading History',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Premium',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}
