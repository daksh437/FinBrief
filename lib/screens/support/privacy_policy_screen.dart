import 'package:flutter/material.dart';
import '../../widgets/legal_document.dart';

/// Privacy Policy.
///
/// Every claim below was checked against what the app actually does — Firebase
/// Auth, the Firestore collections the backend writes, Analytics events,
/// Crashlytics, AdMob, and the Gemini calls that article text and chat
/// messages are sent to. If any of those change, this copy must change too.
///
/// It has NOT been reviewed by a lawyer. Google Play also requires the same
/// policy to be reachable at a public URL.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocument(
      title: 'Privacy Policy',
      lastUpdated: '6 August 2026',
      intro:
          'This policy explains what FinBrief collects, why, and who it is shared with. '
          'FinBrief is a financial news app: it does not sell your personal data.',
      sections: [
        LegalSection(
          'Information you give us',
          'When you create an account we collect your email address, and your name and profile '
          'photo if you sign in with Google. Passwords are handled by Firebase Authentication and '
          'are never visible to us.\n\n'
          'We also store what you choose to save: bookmarked articles, your watchlist, and the '
          'holdings you add to your portfolio (symbol, quantity and the price you enter). '
          'Portfolio entries are figures you type in yourself — we do not connect to your broker '
          'or bank, and we cannot see your real trades or balances.',
        ),
        LegalSection(
          'Information collected automatically',
          'We record how much you use AI features, so free daily limits and credits can be '
          'applied correctly. Firebase Analytics records app events such as opening an article, '
          'running a search, or using an AI action. Firebase Crashlytics collects crash reports '
          'containing your device model, operating system version and the technical details of '
          'the error.\n\n'
          'If you allow notifications, we store a device push token so alerts can reach you. '
          'Reading history, recent searches and chat history are kept only on your device and are '
          'removed when you uninstall the app.',
        ),
        LegalSection(
          'AI processing',
          'When you request a summary, translation, market-impact analysis, or ask a question in '
          'chat, the article text or your message is sent to Google Gemini to generate a '
          'response. Please do not enter information you would not want processed by a '
          'third-party AI service.\n\n'
          'We keep a short record of AI requests and responses, linked to your account, to '
          'operate rate limits, investigate errors and improve quality.',
        ),
        LegalSection(
          'Who we share data with',
          'Google, as our infrastructure provider — Firebase Authentication, Firestore, Cloud '
          'Messaging, Analytics and Crashlytics, and the Gemini API for AI features.\n\n'
          'Google AdMob, which may serve advertising in the app and can use your device '
          'advertising identifier for that purpose.\n\n'
          'Google Play billing, if you buy a subscription or credits. We receive a purchase '
          'confirmation; we never receive your card details.\n\n'
          'Market and news data providers are only ever sent a stock symbol or a search request. '
          'They receive nothing that identifies you.',
        ),
        LegalSection(
          'How long we keep it',
          'Account data is kept while your account exists. Cached news and archived articles are '
          'deleted automatically after 30 days. AI request records and operational logs are kept '
          'for up to 7 days.',
        ),
        LegalSection(
          'Your choices',
          'You can turn notifications off at any time in Settings or in your device settings, and '
          'you can remove individual bookmarks, watchlist entries and portfolio holdings inside '
          'the app.\n\n'
          'To delete your account and the data associated with it, contact us through the Support '
          'section and we will action the request.',
        ),
        LegalSection(
          'Children',
          'FinBrief is not intended for anyone under 18 and we do not knowingly collect data from '
          'children.',
        ),
        LegalSection(
          'Changes and contact',
          'If this policy changes we will update the date at the top of this page. For any '
          'privacy question, or to request deletion of your data, contact us through the Support '
          'section of the app.',
        ),
      ],
    );
  }
}
