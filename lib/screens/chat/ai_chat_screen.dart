import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/chat_history_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';

const _suggestedPrompts = [
  'Explain today\'s Sensex move',
  'Is now a good time for gold?',
  'What is an IPO?',
  'Summarize RBI\'s latest policy',
];

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  _ChatMessage(this.role, this.text);
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ChatHistoryService.getHistory();
    if (!mounted) return;
    setState(() {
      _messages.addAll(history.map((m) => _ChatMessage(m['role']!, m['text']!)));
      _loadingHistory = false;
    });
  }

  Future<void> _persist() async {
    await ChatHistoryService.save(_messages.map((m) => {'role': m.role, 'text': m.text}).toList());
  }

  Future<void> _clearHistory() async {
    await ChatHistoryService.clear();
    setState(() => _messages.clear());
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage('user', text));
      _controller.clear();
      _sending = true;
    });
    await _persist();

    try {
      final reply = await AiService.instance.chat(
        _messages.map((m) => {'role': m.role, 'text': m.text}).toList(),
      );
      setState(() => _messages.add(_ChatMessage('assistant', reply)));
    } on AiInsufficientCreditsException {
      setState(() => _messages.add(
            _ChatMessage('assistant', "You've used today's free AI credits. Upgrade to Premium for unlimited access."),
          ));
    } catch (_) {
      setState(() => _messages.add(_ChatMessage('assistant', 'Something went wrong. Please try again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
      await _persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Assistant'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearHistory),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildSuggestedPrompts(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) return const TypingIndicator();
                          final msg = _messages[index];
                          return ChatBubble(isUser: msg.role == 'user', text: msg.text);
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask about markets, stocks, news...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: () => _send(), icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Try asking...', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _suggestedPrompts
                .map((p) => ActionChip(label: Text(p), onPressed: () => _send(p)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
