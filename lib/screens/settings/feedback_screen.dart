import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_spacing.dart';

class FeedbackScreen extends StatefulWidget {
  /// 'feedback' from Settings, 'bug' when opened as "Report a Bug".
  final String type;

  const FeedbackScreen({super.key, this.type = 'feedback'});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  bool get _isBug => widget.type == 'bug';

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please write something first.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final ok = await FeedbackService.instance.submit(message, type: widget.type);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
      _error = ok ? null : 'Could not send right now. Please try again.';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isBug ? 'Report a Bug' : 'Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _sent
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(_isBug ? 'Thanks — bug report sent!' : 'Thanks for the feedback!'),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_isBug
                      ? 'Describe what went wrong and what you expected to happen.'
                      : 'Tell us what\'s working and what isn\'t.'),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _isBug ? 'Describe the bug...' : 'Your feedback...',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit'),
                  ),
                ],
              ),
      ),
    );
  }
}
