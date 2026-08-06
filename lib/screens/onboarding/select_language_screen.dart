import 'package:flutter/material.dart';
import '../../config/app_languages.dart';
import '../../services/onboarding_prefs.dart';
import '../../theme/app_spacing.dart';
import 'select_interests_screen.dart';

/// First-run language picker.
///
/// The options used to be English / Hindi / Both. Hindi reaches roughly 40% of
/// India, and not the part with the deepest retail equity participation —
/// Gujarat and Maharashtra do. Every listed language is shown in its own
/// script, because someone looking for Gujarati is looking for "ગુજરાતી".
class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  String _selected = AppLanguages.defaultCode;

  Future<void> _continue() async {
    await OnboardingPrefs.setLanguage(_selected);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SelectInterestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose your language', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('News summaries will be read out and translated in this language. '
                      'You can change it any time.'),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            // Scrollable: ten languages don't fit on a small screen, and the
            // list will grow.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: AppLanguages.all.map((l) {
                  final selected = l.code == _selected;
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    elevation: selected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      side: BorderSide(
                        color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(l.native, style: theme.textTheme.titleMedium),
                      subtitle: Text(l.name),
                      trailing: selected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                      onTap: () => setState(() => _selected = l.code),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FilledButton(onPressed: _continue, child: const Text('Continue')),
            ),
          ],
        ),
      ),
    );
  }
}
