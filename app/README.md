# My Schemes — Flutter App

Offline-first browser for 4,000+ Indian government schemes, powered by the
`schemes.db` SQLite database that the repository's weekly GitHub Actions
pipeline builds from the official MyScheme API.

## Features

- Home with featured, trending and recently-updated rails plus new-scheme
  announcements
- 15 browse categories (Agriculture, Women, Students, Senior Citizens,
  Business/MSME, Health, Housing, Employment, Pension, Insurance,
  Scholarships, Divyangjan, Rural Development, Startup, Skill Development)
- Smart filters: central/state, state, age, gender, income, occupation,
  SC/ST/OBC
- Full scheme details: objective, benefits, eligibility, documents, how to
  apply, official website, helpline, last updated, FAQs, related schemes
- Eligibility checker ("You may be eligible for N schemes") in the style of
  the official myScheme personalized discovery
- FTS5 full-text search over names, ministries, keywords and benefits
- Offline bookmarks
- Side-by-side comparison of up to 3 schemes
- In-app notifications: new schemes, database updates, deadline reminders
- 11 languages: English, Hindi, Tamil, Telugu, Marathi, Bengali, Gujarati,
  Kannada, Malayalam, Punjabi, Odia

## Data flow

On first launch the app downloads `schemes.db` (~36 MB) from this
repository's `main` branch and stores it locally; afterwards everything
works offline. Pull-to-refresh (or Settings → Check for updates) performs a
cheap ETag check and only re-downloads when the weekly pipeline has
published a new database.

## Getting started

The repository tracks only the Dart source. Generate the platform shells
once, then run:

```bash
cd app
flutter create --org com.zrix --project-name scheme_app .
flutter pub get
flutter run
```

Android release build: `flutter build apk --release`.

## Tests

```bash
flutter test
```
