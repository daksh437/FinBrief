import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/startup_gate.dart';
import 'theme/app_theme.dart';
import 'widgets/connectivity_banner.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Hold the native splash through Firebase init and the onboarding check, so
  // startup goes splash -> real screen with nothing in between. StartupGate
  // removes it. Without this the splash disappears the moment Flutter renders
  // its first frame, which is before there is anything worth showing.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Firebase.initializeApp();

  // Route both Flutter framework errors and uncaught async/platform errors
  // into Crashlytics. Disabled in debug so local development crashes stay in
  // the console instead of polluting production crash reports.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Best-effort — ad loading failures shouldn't block app startup.
  unawaited(MobileAds.instance.initialize());
  runApp(const FinBriefApp());
}

class FinBriefApp extends StatelessWidget {
  const FinBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'FinBrief',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const StartupGate(),
            builder: (context, child) => ConnectivityBanner(child: child!),
          );
        },
      ),
    );
  }
}
