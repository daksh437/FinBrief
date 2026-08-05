import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mail_outline, size: 48),
            SizedBox(height: AppSpacing.md),
            // TODO: replace with a real support email/contact channel once one exists.
            Text('A support contact channel hasn\'t been set up yet. In the meantime, use the Feedback or Report a Bug options to reach the team.'),
          ],
        ),
      ),
    );
  }
}
