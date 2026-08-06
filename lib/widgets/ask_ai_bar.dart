import 'package:flutter/material.dart';
import '../config/app_languages.dart';
import '../theme/app_spacing.dart';

/// Ask AI actions on the news detail screen. The `mode` values must match the
/// backend's /ai/explain modes.
///
/// "Explain in Hindi" used to live here as a fourth explain mode. It is now a
/// separate translate action with a language picker, because the language
/// belongs to the user, not to the button — someone who reads Gujarati wants
/// every article in Gujarati, not to hunt for a Hindi chip.
const askAiActions = <({String mode, String label, IconData icon})>[
  (mode: 'why-it-matters', label: 'Why it matters', icon: Icons.help_outline),
  (mode: 'future-impact', label: 'Future impact', icon: Icons.timeline),
  (mode: 'beginner', label: 'Beginner mode', icon: Icons.school_outlined),
];

class AskAIBar extends StatelessWidget {
  final void Function(String mode) onAction;

  /// Translate into [language]. Separate from [onAction] because it hits a
  /// different endpoint.
  final void Function(AppLanguage language) onTranslate;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  final String? activeMode;
  final bool loading;

  const AskAIBar({
    super.key,
    required this.onAction,
    required this.onTranslate,
    required this.language,
    required this.onLanguageChanged,
    this.activeMode,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final translating = loading && activeMode == 'translate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask AI', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            // Shows the language in its own script: someone looking for
            // Gujarati is looking for "ગુજરાતી", not the word "Gujarati".
            ActionChip(
              avatar: translating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.translate_rounded, size: 16),
              label: Text('Read in ${language.native}'),
              onPressed: loading ? null : () => onTranslate(language),
            ),
            ActionChip(
              avatar: const Icon(Icons.expand_more, size: 16),
              label: const Text('Change'),
              onPressed: loading ? null : () => _pickLanguage(context),
            ),
            ...askAiActions.map((action) {
              final isActive = loading && activeMode == action.mode;
              return ActionChip(
                avatar: isActive
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(action.icon, size: 16),
                label: Text(action.label),
                // Every chip is disabled while a request is in flight, so a
                // user can't queue several calls against their daily limit.
                onPressed: loading ? null : () => onAction(action.mode),
              );
            }),
          ],
        ),
      ],
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text('Read summaries in', style: Theme.of(context).textTheme.titleMedium),
            ),
            ...AppLanguages.translationTargets.map(
              (l) => ListTile(
                title: Text(l.native),
                subtitle: Text(l.name),
                trailing: l.code == language.code ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(l),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null) onLanguageChanged(picked);
  }
}
