# 🕊️ Divine Quotes – Sacred Wisdom

A Flutter app for **Android, iOS and the web** that shares **60 inspiring quotes** from the **Bible**, **Bhagavad Gita** and **Holy Quran** (20 from each).

Live website: https://varmavinay.github.io/spritual_sos/

---

## ✨ Features

- **60 curated sacred quotes** with scripture citations.
- **New quote** button, or **swipe the card**, for another verse. The same quote never shows twice in a row.
- **Scripture filter:** **All**, ✝️ **Bible**, 🕉️ **Gita** or ☪️ **Quran**.
- **Share** through the native share sheet, or **copy to clipboard**.
- **Daily reminder** with a quote at the time you choose. It never fires the moment you turn it on:
  - **Android / iOS apps:** scheduled with the OS for the next 30 days, each with a different quote, and topped up each time the app opens. On Android, reminders arrive on the exact minute when "Alarms & reminders" is allowed.
  - **Website:** uses **Web Push** through the small push server in [`push-server/`](push-server/), so reminders arrive even when the site is closed.
  - **iPhone / iPad website:** needs **iOS 16.4+** and the site **added to the Home Screen** (Share → Add to Home Screen). The app shows these steps when opened in Safari.
- **Works offline** on the web after the first visit.
- **Light & dark theme** that follows the system setting.

---

## 🚀 Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.13+).

```bash
flutter pub get

flutter run -d chrome     # website
flutter run -d android    # Android device / emulator
flutter run -d ios        # iPhone / simulator (needs a Mac with Xcode)
flutter test
```

### Building releases

```bash
flutter build web --release --base-href /spritual_sos/   # output: build/web
flutter build apk --release                              # or: flutter build appbundle
flutter build ipa --release                              # on macOS
```

The website talks to the push server at the URL in `lib/services/web_push/web_push_web.dart`. To use a different server, build with `--dart-define=PUSH_SERVER_URL=https://...`.

Before publishing to the stores:
- Change the Android `applicationId` in `android/app/build.gradle.kts` and the iOS bundle identifier in Xcode (both still use `com.example.*`).
- Set up a release signing config for Android and a development team for iOS.

### App icons

Icons for every platform are generated from `assets/icon/icon.png`:

```bash
dart run flutter_launcher_icons
```

---

## 🔔 Push server (website reminders)

Browsers can't schedule a notification for later, so the website registers its push subscription with a small [Cloudflare Worker](push-server/src/index.js). Every minute the Worker looks for reminders that are due and sends each one a random quote over Web Push. It's free on Cloudflare's free plan.

| Part | File |
| --- | --- |
| Worker (HTTP API + every-minute cron) | `push-server/src/index.js` |
| Web Push encryption + VAPID signing | `push-server/src/webpush.js` |
| Time-zone / daylight-saving maths | `push-server/src/time.js` |
| Database table | `push-server/schema.sql` |
| Quotes sent in notifications | `push-server/src/quotes.json` (generated, see below) |
| Browser side | `web/push_sw.js`, `lib/services/web_push/` |

### First-time deploy

```bash
cd push-server
npm install
npx wrangler login
npx wrangler d1 create divine-quotes-push       # copy database_id into wrangler.toml
npm run db:init                                 # create the table
npm run vapid                                   # only if .vapid-private.json doesn't exist yet
npx wrangler secret put VAPID_PRIVATE_KEY < .vapid-private.json
npm run deploy
```

Keep `.vapid-private.json` safe and out of git. Generating new keys means every visitor has to turn reminders off and on again.

### After editing quotes

```bash
dart run tool/export_quotes.dart   # refresh push-server/src/quotes.json
cd push-server && npm run deploy
```

### Testing locally

```bash
cd push-server
npm test                                            # encryption, VAPID and time-zone tests
npm run db:init:local
npx wrangler dev --test-scheduled --port 8787 --ip 127.0.0.1
node scripts/fake-push-service.mjs                  # in another terminal: subscribes a fake browser
curl "http://127.0.0.1:8787/__scheduled?cron=*+*+*+*+*"   # run the cron; due pushes are printed
```

---

## 🌐 Publishing the website on GitHub Pages

`.github/workflows/deploy-web.yml` builds the Flutter web app and deploys it on every push to `main` (repo **Settings → Pages → Source: GitHub Actions**).

---

## 📂 Project structure

```
lib/
├── main.dart                         # App entry
├── theme.dart                        # Material 3 light & dark colour schemes
├── models/quote.dart                 # Quote + ScriptureSource
├── data/quotes.dart                  # The 60 quotes + random/filter helpers
├── services/
│   ├── settings_store.dart           # Saved preferences
│   ├── notification_service.dart     # Daily reminders (mobile + web)
│   ├── reminder_types.dart
│   └── web_push/                     # Web Push client (web) + stub (mobile)
├── screens/home_screen.dart          # Main screen
└── widgets/
    ├── quote_card.dart               # Swipeable quote card
    ├── scripture_filter.dart         # All / Bible / Gita / Quran tabs
    └── reminder_card.dart            # Reminder toggle, time, iPhone help
web/push_sw.js                        # Service worker: push, notification taps, offline
push-server/                          # Cloudflare Worker that sends web reminders
tool/export_quotes.dart               # Copies quotes to the push server
test/                                 # Flutter tests
```
