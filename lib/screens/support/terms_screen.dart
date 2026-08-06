import 'package:flutter/material.dart';
import '../../widgets/legal_document.dart';

/// Terms of Service.
///
/// The "not investment advice" section is the important one and is written to
/// match what the app actually shows: AI summaries, market-impact sentiment,
/// and an "In Focus Today" list. It has NOT been reviewed by a lawyer, and an
/// app that comments on specific securities to Indian users should be checked
/// against SEBI's investment-adviser and research-analyst regulations before
/// release.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocument(
      title: 'Terms of Service',
      lastUpdated: '6 August 2026',
      intro:
          'By using FinBrief you agree to these terms. Please read the section on investment '
          'advice carefully — it explains the limits of what this app is.',
      sections: [
        LegalSection(
          'Not investment advice',
          'FinBrief provides news and general information only. Nothing in the app is investment, '
          'financial, legal or tax advice, and nothing in it is a recommendation to buy, sell or '
          'hold any security.\n\n'
          'This includes AI summaries, market-impact sentiment, the "In Focus Today" list and any '
          'other generated content. Those describe what the news says; they do not tell you what '
          'to do. We are not a SEBI-registered investment adviser or research analyst. Consider '
          'speaking to a registered adviser before making any investment decision.\n\n'
          'You are solely responsible for your own investment decisions and their outcomes.',
        ),
        LegalSection(
          'AI-generated content can be wrong',
          'Summaries, translations and analysis are produced automatically by AI. They can '
          'misread an article, omit important context, or state something incorrectly — including '
          'numbers, company names and dates. Always read the original article, which we link to '
          'on every item, before relying on anything.',
        ),
        LegalSection(
          'Market data',
          'Prices, indices and other market figures come from third-party sources and are '
          'provided as-is. They may be delayed, incomplete or temporarily unavailable, and they '
          'are not suitable for trading decisions. Where a price cannot be retrieved we show '
          'nothing rather than an estimate.\n\n'
          'Portfolio values are calculated from holdings you enter yourself and are an indication '
          'only, not a statement of account.',
        ),
        LegalSection(
          'Your account',
          'You must be 18 or older to use FinBrief. Keep your login details secure — you are '
          'responsible for activity on your account. Do not misuse the service: no automated '
          'scraping, no attempts to bypass usage limits, and no reselling or redistributing our '
          'content.',
        ),
        LegalSection(
          'Free usage, subscriptions and credits',
          'Free accounts include a limited number of AI actions per day. Subscriptions and credit '
          'packs are sold through Google Play, and payments, renewals and refunds are handled '
          'under Google Play\'s terms.\n\n'
          'We may change the limits and pricing of free and paid tiers. Where a change materially '
          'reduces what you have already paid for, we will tell you in advance.',
        ),
        LegalSection(
          'News content',
          'Headlines, snippets and images come from third-party publishers and remain their '
          'property. We link to the original article and do not reproduce full articles.',
        ),
        LegalSection(
          'Availability and liability',
          'FinBrief is provided as-is. We do not guarantee it will be available without '
          'interruption, or that news, data or AI features will always be accurate or current.\n\n'
          'To the fullest extent permitted by law, we are not liable for any trading or '
          'investment loss, or for any indirect or consequential loss, arising from your use of '
          'the app.',
        ),
        LegalSection(
          'Changes and contact',
          'We may update these terms; the date at the top of this page shows when they last '
          'changed. Continuing to use the app after a change means you accept the updated terms. '
          'Questions can be sent through the Support section of the app.',
        ),
      ],
    );
  }
}
