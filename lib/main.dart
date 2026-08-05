import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/connectivity_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            home: const SplashScreen(),
            builder: (context, child) => ConnectivityBanner(child: child!),
          );
        },
      ),
    );
  }
}
