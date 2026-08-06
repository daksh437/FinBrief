import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/onboarding_prefs.dart';
import 'auth_gate.dart';
import 'onboarding/onboarding_screen.dart';

/// Decides where the app opens: onboarding for a first run, otherwise the auth
/// gate.
///
/// This replaced a SplashScreen widget that drew its own white screen with a
/// generic Material icon and then waited a hardcoded two seconds. Because the
/// native splash had already shown the real logo on a purple background, users
/// saw two different splashes back to back — and the second one added two
/// seconds of nothing to every cold start.
///
/// Now the native splash is held up until this check resolves (a preference
/// read, a few milliseconds) and removed once the real first screen is built,
/// so there is exactly one splash and no artificial delay.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    bool seen;
    try {
      seen = await OnboardingPrefs.hasSeenOnboarding();
    } catch (_) {
      // A failed preference read must not strand the user on the splash —
      // showing onboarding again is the harmless outcome.
      seen = false;
    }
    if (!mounted) return;
    setState(() => _hasSeenOnboarding = seen);
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing is drawn until the decision is made; the native splash is still
    // on screen at this point, so this never flashes.
    if (_hasSeenOnboarding == null) return const SizedBox.shrink();
    return _hasSeenOnboarding! ? const AuthGate() : const OnboardingScreen();
  }
}
