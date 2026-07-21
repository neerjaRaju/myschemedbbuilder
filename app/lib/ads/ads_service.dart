import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_manager.dart';

/// Central AdMob configuration and lifecycle.
///
/// Responsibilities:
/// * gather UMP consent before any ad request (policy requirement),
/// * initialize the Mobile Ads SDK only after consent is resolved,
/// * hold the real ad unit ids in one place (test ids by default),
/// * expose whether ads may currently be requested.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool _canRequestAds = false;

  /// Whether ads may be requested right now (consent resolved + SDK ready).
  bool get canShowAds => _initialized && _canRequestAds;

  /// Banner unit id. Replace the release ids with your own AdMob units.
  /// Google's official test ids are used in debug/never-configured builds so
  /// development never risks policy violations from clicking live ads.
  static String get bannerAdUnitId {
    const androidRelease = String.fromEnvironment('ADMOB_BANNER_ANDROID');
    const iosRelease = String.fromEnvironment('ADMOB_BANNER_IOS');
    if (Platform.isAndroid) {
      return androidRelease.isNotEmpty
          ? androidRelease
          : 'ca-app-pub-3940256099942544/6300978111'; // test banner
    }
    return iosRelease.isNotEmpty
        ? iosRelease
        : 'ca-app-pub-3940256099942544/2934735716'; // test banner
  }

  /// Gathers consent, then initializes the SDK. Safe to call once at startup.
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. UMP consent must be resolved before requesting ads.
    await ConsentManager.gatherConsent();
    _canRequestAds = await ConsentManager.canRequestAds();

    // 2. Only initialize the Ads SDK once consent allows ad requests.
    if (_canRequestAds) {
      await MobileAds.instance.initialize();
      // Child-directed / content rating: this is a general-audience civic
      // information app (not directed to children), rated for general use.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
    }
    _initialized = true;
  }

  /// Re-checks consent (e.g. after the user changes it in settings).
  Future<void> refreshConsent() async {
    _canRequestAds = await ConsentManager.canRequestAds();
    if (_canRequestAds && !_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
  }
}
