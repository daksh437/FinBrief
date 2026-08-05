import 'package:flutter/material.dart';
import '../../services/onboarding_prefs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../auth_gate.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingPage(this.icon, this.title, this.subtitle);
}

const _pages = [
  _OnboardingPage(
    Icons.bolt_rounded,
    'Real-time Financial News',
    'Breaking news the moment it happens — stocks, crypto, gold, forex, IPOs.',
  ),
  _OnboardingPage(
    Icons.translate_rounded,
    'AI Hindi Summaries & AI Chat',
    'Complex financial news explained simply in Hindi or English, plus an AI assistant for your questions.',
  ),
  _OnboardingPage(
    Icons.notifications_active_rounded,
    'Portfolio Alerts & Personalized Experience',
    'Portfolio-based alerts and a feed tailored to the topics you care about.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await OnboardingPrefs.markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_index == _pages.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                    }
                  },
                  child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
