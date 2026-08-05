import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/onboarding_prefs.dart';
import '../../widgets/settings_tile.dart';
import '../notifications/notification_settings_screen.dart';
import '../support/support_screen.dart';
import 'about_screen.dart';

const _themeLabels = {
  ThemeMode.light: 'Light',
  ThemeMode.dark: 'Dark',
  ThemeMode.system: 'System default',
};

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await OnboardingPrefs.getLanguage();
    if (mounted) setState(() => _language = language);
  }

  Future<void> _changeLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose language'),
        children: ['English', 'Hindi', 'Both']
            .map((lang) => SimpleDialogOption(onPressed: () => Navigator.pop(context, lang), child: Text(lang)))
            .toList(),
      ),
    );
    if (selected != null) {
      await OnboardingPrefs.setLanguage(selected);
      setState(() => _language = selected);
    }
  }

  Future<void> _changeTheme(ThemeProvider themeProvider) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose theme'),
        children: ThemeMode.values
            .map((mode) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, mode),
                  child: Text(_themeLabels[mode]!),
                ))
            .toList(),
      ),
    );
    if (selected != null) await themeProvider.setMode(selected);
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text('This clears your locally-stored reading history, search history, and AI chat history. Bookmarks and watchlist are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await CacheService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _language,
            onTap: _changeLanguage,
          ),
          SettingsTile(
            icon: Icons.brightness_6_outlined,
            title: 'Theme',
            subtitle: _themeLabels[themeProvider.mode],
            onTap: () => _changeTheme(themeProvider),
          ),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification preferences',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear Cache',
            onTap: _clearCache,
          ),
          SettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.logout,
            title: 'Sign out',
            onTap: _confirmSignOut,
          ),
        ],
      ),
    );
  }
}
