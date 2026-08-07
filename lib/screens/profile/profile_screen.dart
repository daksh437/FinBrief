import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/profile_header.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../bookmarks/history_screen.dart';
import '../funds/funds_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The profile was loaded once at startup, so the AI usage counter here
    // could show "3 / 5 used" while the server had already refused the sixth
    // call. Re-read it whenever this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().refresh();
    });
  }

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
                      // Premium's fair-use ceiling is deliberately not shown as
                      // a countdown — it exists to stop runaway usage, not to
                      // ration a paying subscriber.
                      if (!profile.showsUsageCounter)
                        const Text('Unlimited (Premium)')
                      else ...[
                        Text('${profile.aiUsedToday} / ${profile.dailyLimit} used today'),
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: profile.dailyLimit == 0 ? 0 : profile.aiUsedToday / profile.dailyLimit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Resets at midnight UTC. Go Premium to remove the limit.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
            icon: Icons.pie_chart_outline,
            title: 'Mutual Funds',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FundsScreen())),
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
          const Divider(),
          // Google Play requires apps that create accounts to offer deletion
          // from inside the app. Kept visually distinct from the tiles above so
          // it can't be tapped by mistake.
          SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            iconColor: Theme.of(context).colorScheme.error,
            titleColor: Theme.of(context).colorScheme.error,
            trailing: const SizedBox.shrink(),
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, along with your bookmarks, '
          'watchlist and portfolio. It cannot be undone.\n\n'
          'Any active subscription must be cancelled separately in Google Play.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Deletion touches several collections, so it can take a moment — block
    // interaction rather than leave the screen looking idle.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService.instance.deleteAccount();
      // The auth stream drops the app back to the login screen on its own;
      // just clear the spinner.
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AccountDeletionFailed ? e.message : 'Could not delete your account.')),
      );
    }
  }
}
