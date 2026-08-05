import 'package:flutter/material.dart';
import '../../services/onboarding_prefs.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/category_chip.dart';
import 'select_interests_screen.dart';

const _languages = ['English', 'Hindi', 'Both'];

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  String _selected = _languages.first;

  Future<void> _continue() async {
    await OnboardingPrefs.setLanguage(_selected);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SelectInterestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Choose your language', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              const Text('AI summaries and translations will use this language.'),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _languages
                    .map((lang) => CategoryChip(
                          label: lang,
                          selected: _selected == lang,
                          onTap: () => setState(() => _selected = lang),
                        ))
                    .toList(),
              ),
              const Spacer(),
              FilledButton(onPressed: _continue, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
