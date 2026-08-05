import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/settings_tile.dart';
import '../settings/feedback_screen.dart';
import 'contact_screen.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _rateApp(BuildContext context) async {
    // Play Store listing for this app's package — will only resolve once
    // FinBrief is actually published; that's expected pre-launch, not a
    // broken link. Uses https (not market://) to avoid needing an extra
    // Android package-visibility <queries> declaration for a custom scheme.
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.FinBrief');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.help_outline,
            title: 'FAQ',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqScreen())),
          ),
          SettingsTile(
            icon: Icons.mail_outline,
            title: 'Contact Us',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen())),
          ),
          SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackScreen(type: 'bug')),
            ),
          ),
          SettingsTile(
            icon: Icons.star_outline,
            title: 'Rate the App',
            onTap: () => _rateApp(context),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
          ),
        ],
      ),
    );
  }
}
