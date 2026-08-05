import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/onboarding_prefs.dart';
import '../widgets/error_state.dart';
import 'auth/login_screen.dart';
import 'home/main_shell.dart';
import 'onboarding/select_language_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return _SignedInGate();
      },
    );
  }
}

class _SignedInGate extends StatefulWidget {
  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  bool? _needsLanguageSetup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<UserProvider>().bootstrapAndLoad();
      // Best-effort — don't block app usage if notification permission/token fails.
      NotificationService.instance.registerToken().catchError((_) {});

      final languageDone = await OnboardingPrefs.hasSelectedLanguage();
      final interestsDone = await OnboardingPrefs.hasSelectedInterests();
      if (mounted) setState(() => _needsLanguageSetup = !(languageDone && interestsDone));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.loading || _needsLanguageSetup == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userProvider.profile == null) {
      return Scaffold(
        body: ErrorState(
          message: userProvider.error ?? 'Could not load your profile.',
          onRetry: () => context.read<UserProvider>().bootstrapAndLoad(),
        ),
      );
    }

    return _needsLanguageSetup! ? const SelectLanguageScreen() : const MainShell();
  }
}
