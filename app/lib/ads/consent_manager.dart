import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google User Messaging Platform (UMP) consent gate.
///
/// AdMob policy (and GDPR / ePrivacy in the EEA + UK) requires collecting
/// user consent through a certified CMP before requesting personalized ads.
/// This wraps the UMP SDK that ships inside `google_mobile_ads`:
///
/// 1. request the latest consent info,
/// 2. load and show the consent form if one is required,
/// 3. expose [canRequestAds] so ad requests only fire once consent
///    (or "no consent required") is resolved.
///
/// Configure the actual consent form and messages in the AdMob console under
/// Privacy & messaging → European regulations.
class ConsentManager {
  const ConsentManager._();

  /// Gathers consent, showing the form when UMP says it is required.
  ///
  /// Never throws: on any UMP error the app continues, and ad requests stay
  /// gated by [canRequestAds].
  static Future<void> gatherConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters(
      // Set to true only while testing under-age-of-consent handling.
      tagForUnderAgeOfConsent: false,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!completer.isCompleted) completer.complete();
          });
        } catch (_) {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// Whether ad requests are currently permitted by the user's consent
  /// choice. Ad widgets must check this before loading.
  static Future<bool> canRequestAds() =>
      ConsentInformation.instance.canRequestAds();

  /// Whether a privacy options entry point (e.g. a "Manage ad privacy"
  /// settings row) must be shown so EEA users can change their choice.
  static Future<bool> isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Reopens the consent form so the user can change their choice.
  static Future<void> showPrivacyOptionsForm() async {
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }
}
