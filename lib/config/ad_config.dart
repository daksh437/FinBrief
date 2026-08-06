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
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  static const _liveBanner = 'ca-app-pub-6637437102244163/3061903872';
  static const _liveNative = 'ca-app-pub-6637437102244163/7739515482';

  static String get banner => _pick(_liveBanner, _testBanner);
  static String get native => _pick(_liveNative, _testNative);

  static String _pick(String live, String test) =>
      (kDebugMode || live.isEmpty) ? test : live;

  /// True when real, billable ads are being requested.
  static bool get isLive => !kDebugMode && _liveBanner.isNotEmpty;

  /// Native ads in the feed are off until the banner has been live long enough
  /// to show what it does to retention. A brand-new app carrying a banner on
  /// every article *and* ads inside the feed reads as ad-heavy, which costs
  /// more in uninstalls than the extra impressions are worth.
  static const feedNativeAdsEnabled = false;

  /// Show a native ad after every Nth article once the above is enabled. Six is
  /// often enough to matter and rare enough that the feed still reads as news.
  static const nativeAdInterval = 6;
}
