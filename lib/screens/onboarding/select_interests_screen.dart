import 'package:flutter/material.dart';
import '../../services/onboarding_prefs.dart';
import '../../theme/app_spacing.dart';
import '../home/main_shell.dart';

const _interests = ['Stocks', 'Crypto', 'Gold', 'Forex', 'IPOs', 'Mutual Funds', 'Economy', 'Global Markets'];

class SelectInterestsScreen extends StatefulWidget {
  const SelectInterestsScreen({super.key});

  @override
  State<SelectInterestsScreen> createState() => _SelectInterestsScreenState();
}

class _SelectInterestsScreenState extends State<SelectInterestsScreen> {
  final Set<String> _selected = {};

  Future<void> _finish() async {
    await OnboardingPrefs.setInterests(_selected.toList());
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
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
              Text('What are you interested in?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              const Text('Pick a few — you can change this later in Settings.'),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _interests.map((interest) {
                  final selected = _selected.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _selected.add(interest) : _selected.remove(interest)),
                  );
                }).toList(),
              ),
              const Spacer(),
              FilledButton(onPressed: _finish, child: const Text('Finish')),
            ],
          ),
        ),
      ),
    );
  }
}
