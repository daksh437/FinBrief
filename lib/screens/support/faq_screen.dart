import 'package:flutter/material.dart';

const _faqs = [
  (
    'What is FinBrief?',
    'FinBrief is an AI-powered financial news app that summarizes breaking news, translates it to Hindi, and explains why it matters for the market.',
  ),
  (
    'How do free AI credits work?',
    'New accounts get a 7-day unlimited trial. After that, free accounts get a limited number of AI actions (translate, summary, chat) per day, resetting at midnight UTC. Premium accounts get unlimited AI.',
  ),
  (
    'What does Premium include?',
    'Unlimited AI translation, summaries and chat, no ads, and WhatsApp alerts.',
  ),
  (
    'Is the market data real-time?',
    'Market indices, crypto, gold, forex and portfolio quotes are currently illustrative placeholder data — a live market-data provider isn\'t connected yet.',
  ),
  (
    'How do I delete my bookmarks or history?',
    'Go to Bookmarks or Reading History from your Profile and remove items individually, or use "Clear Cache" in Settings to reset locally-stored history at once.',
  ),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        children: _faqs
            .map((faq) => ExpansionTile(
                  title: Text(faq.$1),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Align(alignment: Alignment.centerLeft, child: Text(faq.$2))],
                ))
            .toList(),
      ),
    );
  }
}
