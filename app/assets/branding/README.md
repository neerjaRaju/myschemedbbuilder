# Branding & Play Store assets

All source images live in `assets/icon/` and `assets/branding/`.

| File | Size | Use |
| --- | --- | --- |
| `icon/icon.png` | 1024² | App launcher icon / Play Store 512 icon (violet, full-bleed) |
| `icon/icon_foreground.png` | 1024² | Android adaptive-icon foreground (transparent, padded) |
| `icon/notification_icon.png` | 512² | Monochrome icon (adaptive monochrome + status-bar notification) |
| `icon/splash_logo.png` | 1024² | Splash logo (violet clipboard, shown on white) |
| `branding/feature_graphic.png` | 1024×500 | Play Store feature graphic / banner |

## Generate launcher icons and splash

After running `flutter create .` to produce the platform folders:

```bash
cd app
flutter pub get
dart run flutter_launcher_icons          # launcher + adaptive + monochrome
dart run flutter_native_splash:create    # white splash with the logo
```

- Launcher icon: violet (`#6C4DF0`) adaptive background, clipboard foreground.
- Splash: **white** background (`#FFFFFF`) with the violet logo, including the
  Android 12+ splash API.

## Notification (status-bar) icon

Android status-bar icons must be a white silhouette on transparent.
`notification_icon.png` is that silhouette. `flutter_launcher_icons` wires it
in as the adaptive monochrome layer; to also use it for runtime
notifications, copy it into the drawable buckets and reference it:

```bash
# from app/ after `flutter create .`
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p android/app/src/main/res/drawable-$d
done
# place resized copies as ic_stat_notification.png in each bucket
```

Then in `AndroidManifest.xml` (inside `<application>`):

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_stat_notification" />
```

## Play Store listing

- **App icon**: upload `icon/icon.png` (Play Console accepts 512×512; export
  or let it downscale).
- **Feature graphic**: upload `branding/feature_graphic.png` (1024×500).
- **Screenshots**: capture from a running device (phone + 7"/10" tablet).
