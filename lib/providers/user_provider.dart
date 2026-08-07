import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/profile_cache_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? profile;
  bool loading = false;
  String? error;

  /// True when [profile] came from the local cache because the network call
  /// failed — the UI can use this to show a "showing offline data" hint.
  bool isStale = false;

  Future<void> bootstrapAndLoad() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await ApiService.instance.post('/auth/bootstrap');
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        profile = UserProfile.fromJson(data);
        isStale = false;
        await ProfileCacheService.save(data);
        // Tag analytics + crash reports with the uid so issues can be traced
        // back to a specific account.
        AnalyticsService.instance.setUserId(profile!.uid);
        FirebaseCrashlytics.instance.setUserIdentifier(profile!.uid);
      } else {
        // Prefer the friendly `message` from ApiService; fall back to the raw
        // error code only if the backend returned one without a message.
        error = res['message'] as String? ?? res['error'] as String? ?? 'Could not load your profile.';
        await _fallBackToCache();
      }
    } catch (e) {
      error = 'Could not reach the server. Check your connection and try again.';
      await _fallBackToCache();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Lets the app open into its normal UI (with stale data) instead of a hard
  // error screen when the profile request fails but we've loaded it before.
  Future<void> _fallBackToCache() async {
    final cached = await ProfileCacheService.load();
    if (cached == null) return;
    try {
      profile = UserProfile.fromJson(cached);
      isStale = true;
    } catch (_) {
      // Cached shape no longer parses (e.g. model changed) — leave the error
      // state in place rather than showing a half-broken profile.
    }
  }

  /// Re-reads the profile without the loading state.
  ///
  /// The AI usage counter lives on the profile, which was loaded once at
  /// startup and never again — so Profile could sit showing "3 / 5 used" while
  /// the server had already refused the sixth call. Screens that display the
  /// counter refresh through this on open.
  ///
  /// Silent on failure: this is a background correction, and replacing a
  /// slightly stale number with an error would be worse.
  Future<void> refresh() async {
    try {
      final res = await ApiService.instance.get('/auth/profile');
      if (res['success'] != true) return;
      profile = UserProfile.fromJson(res['data'] as Map<String, dynamic>);
      isStale = false;
      notifyListeners();
    } catch (_) {
      // Keep whatever is on screen.
    }
  }

  /// Records that an AI action was just used, so the counter moves without
  /// waiting for a round trip. The server remains the authority — this only
  /// keeps the display honest between refreshes.
  void noteAiUsed({bool limitReached = false}) {
    final current = profile;
    if (current == null) return;

    final used = limitReached ? current.dailyLimit : current.aiUsedToday + 1;
    profile = UserProfile(
      uid: current.uid,
      plan: current.plan,
      email: current.email,
      aiUsedToday: used.clamp(0, current.dailyLimit),
    );
    notifyListeners();
  }

  void clear() {
    profile = null;
    error = null;
    isStale = false;
    ProfileCacheService.clear();
    notifyListeners();
  }
}
