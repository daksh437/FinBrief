import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/support_config.dart';
import '../../theme/app_spacing.dart';

/// Support contact.
///
/// Google Play requires a reachable support channel, and the published privacy
/// and account-deletion pages point users at the same address — see
/// [SupportConfig], which is the single place to change it.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(Icons.mail_outline, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Get in touch', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Questions, problems, or a request to delete your data — email us and '
            'we usually reply ${SupportConfig.responseTime}.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              subtitle: const Text(SupportConfig.email),
              trailing: IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_outlined),
                // Not every device has a mail app configured, so copying is
                // offered alongside the mailto link rather than instead of it.
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: SupportConfig.email));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email address copied')),
                  );
                },
              ),
              onTap: () => _composeEmail(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => _composeEmail(context),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send us an email'),
          ),
          const SizedBox(height: AppSpacing.lg * 2),
          Text('Other ways to reach us', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The Feedback and Report a Bug options in Support go straight to the '
            'same team and include your app version, which helps us reproduce '
            'the problem faster.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Future<void> _composeEmail(BuildContext context) async {
    // Uri's query encoding turns spaces into "+", which some mail clients show
    // literally in the subject line, so the query is built by hand.
    final uri = Uri.parse(
      'mailto:${SupportConfig.email}?subject=${Uri.encodeComponent('FinBrief support')}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      await Clipboard.setData(const ClipboardData(text: SupportConfig.email));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mail app found — address copied instead')),
      );
    }
  }
}
