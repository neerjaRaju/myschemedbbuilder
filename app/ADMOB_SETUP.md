# AdMob & Play policy checklist

The app now implements the **code-side** AdMob policy requirements. A few
steps still need real values from your AdMob/Play accounts — they cannot be
hard-coded.

## Implemented in code

- **UMP consent** (`lib/ads/consent_manager.dart`) — requests consent info,
  shows the CMP form when required (EEA/UK), and gates ad requests.
- **Consent-gated init** (`lib/ads/ads_service.dart`) — the Mobile Ads SDK is
  initialized and ads are requested **only after** consent is resolved and
  `canRequestAds` is true.
- **Content rating** — request configuration sets `MaxAdContentRating.g` and
  leaves child-directed treatment unspecified (general-audience app).
- **No empty ad space / no ads before consent** (`lib/widgets/ad_banner.dart`).
- **"Manage ad privacy"** entry point in Settings for EEA users, plus a
  **Privacy Policy** link.
- **Test ad units by default** — release units are injected via
  `--dart-define` so development never clicks live ads.

## You must still configure

### 1. AdMob App ID (required — app crashes without it)

**Android** — `android/app/src/main/AndroidManifest.xml`, inside
`<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

### 2. Real ad unit ids (release builds)

Pass your live units at build time so test ids stay in debug:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/AAAA \
  --dart-define=ADMOB_BANNER_IOS=ca-app-pub-XXXX/BBBB
```

### 3. UMP consent form

In the **AdMob console → Privacy & messaging → European regulations**, create
and publish a GDPR message and (optionally) an IDFA / ATT message. The code
already calls `loadAndShowConsentFormIfRequired`; without a published message
UMP simply reports "no consent required".

### 4. Privacy policy (required by Play & AdMob)

Host `PRIVACY_POLICY.md` (in this folder) as a public web page and put its URL
in:
- `lib/screens/settings_screen.dart` → `_privacyPolicyUrl`
- Play Console → App content → Privacy policy
- AdMob → app settings

### 5. Play Data safety form

Declare in Play Console → App content → Data safety that the app (via the
Google Mobile Ads SDK) may collect **Device or other IDs** and **App activity**
for **Advertising or marketing**. See Google's
"Data disclosure" guidance for the Mobile Ads SDK.

### 6. Families policy

This is a general-audience app, so do **not** opt into the Designed for
Families programme. If your target audience includes children, you must switch
to child-directed treatment and use only Families-approved ad SDKs.

## Verify before release

- Ads never appear on the splash screen or over interactive controls.
- With a test EEA region, the consent form appears on first launch and the
  "Manage ad privacy" row shows in Settings.
- `flutter analyze` is clean and the app runs with test ad ids.
