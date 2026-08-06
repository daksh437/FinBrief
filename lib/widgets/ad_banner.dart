import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../config/ad_config.dart';
import '../providers/user_provider.dart';

/// An anchored adaptive banner.
///
/// Renders nothing at all for Premium subscribers — "no ads" is a headline
/// benefit they paid for, and showing one anyway is how you earn a refund and
/// a one-star review. The check lives inside the widget rather than at each
/// call site so a new placement can't forget it.
///
/// It also occupies zero height until an ad has actually loaded, so a failed
/// or slow fill leaves a blank strip pinned to the bottom of the screen rather
/// than a visible gap in the layout.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Deferred to here rather than initState because the adaptive size needs
    // the screen width, and the premium check needs the provider.
    if (!_requested) _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (context.read<UserProvider>().profile?.isPremium ?? false) return;
    _requested = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdConfig.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          // No fill is normal, especially for a new app that AdMob has not
          // reviewed yet. Drop it quietly; the slot simply stays collapsed.
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<UserProvider>().profile?.isPremium ?? false;
    if (isPremium || !_loaded || _ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
