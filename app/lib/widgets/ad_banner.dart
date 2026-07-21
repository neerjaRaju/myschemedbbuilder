import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ads_service.dart';

/// A consent-gated adaptive banner ad.
///
/// Renders nothing until: consent has been resolved and allows ad requests
/// (see [AdsService]), and the banner has actually loaded. This keeps the app
/// policy-compliant — no ad requests fire before UMP consent, and no empty ad
/// space is shown on failure.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    // Policy gate: never request an ad before consent is resolved.
    if (!AdsService.instance.canShowAds) return;

    final ad = BannerAd(
      adUnitId: AdsService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    // No reserved space until an ad actually loads — avoids blank gaps.
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      height: ad.size.height.toDouble() + 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}
