import 'package:flutter/material.dart';
import '../services/onboarding_prefs.dart';
import '../theme/app_colors.dart';
import 'auth_gate.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final seen = await OnboardingPrefs.hasSeenOnboarding();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => seen ? const AuthGate() : const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // v3 blueprint calls for a white splash background specifically,
      // even though the rest of the app now uses AppColors.background.
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insights_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'FinBrief',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
