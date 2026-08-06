import 'package:flutter/foundation.dart';

/// AdMob unit ids.
///
/// Debug builds ALWAYS use Google's test units. Requesting a live ad while
/// developing — and then tapping it — is what Google classifies as invalid
/// traffic, and the usual outcome is a suspended AdMob account rather than a
/// warning. The split is enforced here rather than left to each call site,
/// because it only takes forgetting once.
///
/// The App ID in AndroidManifest.xml is the real one in every build; that is
/// fine, as it only identifies the publisher and serves nothing on its own.
class AdConfig {
  AdConfig._();

  // Google's public test units — safe to click, serve fake ads.
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  // TODO: paste the real unit ids from AdMob → Ad units. Until then release
  // builds also fall back to test units, which show ads but earn nothing —
  // deliberately, so a half-configured release can't look like it is working.
  static const _liveRewarded = '';
  static const _liveNative = '';

  static String get rewarded => _pick(_liveRewarded, _testRewarded);
  static String get native => _pick(_liveNative, _testNative);

  static String _pick(String live, String test) =>
      (kDebugMode || live.isEmpty) ? test : live;

  /// True when real, billable ads are being requested. Used for the one-off
  /// startup log so a misconfigured release is obvious rather than silent.
  static bool get isLive => !kDebugMode && _liveRewarded.isNotEmpty;

  /// Show a native ad after every Nth article in the feed.
  ///
  /// Six is a compromise: often enough to matter, rare enough that the feed
  /// still reads as news. Ads placed nearer than this start costing more in
  /// uninstalls than they earn.
  static const nativeAdInterval = 6;
}
