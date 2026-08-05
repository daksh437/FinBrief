import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// The Ask AI actions offered on the news detail screen. The `mode` values
/// must match the backend's /ai/explain modes.
const askAiActions = <({String mode, String label, IconData icon})>[
  (mode: 'hindi', label: 'Explain in Hindi', icon: Icons.translate_rounded),
  (mode: 'why-it-matters', label: 'Why it matters', icon: Icons.help_outline),
  (mode: 'future-impact', label: 'Future impact', icon: Icons.timeline),
  (mode: 'beginner', label: 'Beginner mode', icon: Icons.school_outlined),
];

class AskAIBar extends StatelessWidget {
  final void Function(String mode) onAction;
  final String? activeMode;
  final bool loading;

  const AskAIBar({
    super.key,
    required this.onAction,
    this.activeMode,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask AI', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: askAiActions.map((action) {
            final isActive = loading && activeMode == action.mode;
            return ActionChip(
              avatar: isActive
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(action.icon, size: 16),
              label: Text(action.label),
              // Disable every chip while a request is in flight so a user
              // can't queue up several credit-consuming calls at once.
              onPressed: loading ? null : () => onAction(action.mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}
