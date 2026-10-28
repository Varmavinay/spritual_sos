# Spiritual SOS

*Small words. A little more light.*

A Flutter app for **Android, iOS and the web** with a daily message from the **Bible**, the **Bhagavad Gita** and the **Quran** (60 verses, 20 from each).

Live website: https://varmavinay.github.io/spritual_sos/

---

## ✨ Features

- **Welcome screen** on first launch, then three tabs: **Home**, **History** and **Profile**, plus a side menu.
- **Today's message:** one verse a day (or the one your daily notification brought). Filter by **All / Bible / Gita / Quran**, swipe the card or tap **Show another message** for more.
- **Message page:** the full verse with its citation, **Save** (bookmark), **Share**, and a **Reflection** prompt with a note you can write. Notes stay on the device.
- **Save** messages you love. Saved messages are kept on this device and listed under **History → Saved**.
- **History → Received:** every daily message delivered to this device, newest first. Tap one to open it.
- **Profile:** an editable name, counts of saved / received / reflections, and settings.
- **Daily message** at the time you choose, from the **holy book you choose** (the Bible, the Bhagavad Gita, the Quran, or all three at random). It never fires the moment you turn it on. Tapping the notification opens that message.
  - **Android / iOS apps:** scheduled with the OS for the next 30 days, each with a different quote, and topped up each time the app opens. On Android, reminders arrive on the exact minute when "Alarms & reminders" is allowed.
  - **Website:** uses **Web Push** through the small push server in [`push-server/`](push-server/), so messages arrive even when the site is closed. The service worker records each one for the history.
  - **iPhone / iPad website:** needs **iOS 16.4+** and the site **added to the Home Screen** (Share → Add to Home Screen). The app shows these steps when opened in Safari.
- **Works offline** on the web after the first visit.
- **Light & dark theme** (warm paper and terracotta) that follows the system setting.

Everything personal (name, saved messages, reflections, history) is stored only on the device. The push server only knows a browser's push address, its reminder time, time zone and chosen holy book.

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

The icon is drawn in code from the welcome-screen emblem (`tool/render_icon_test.dart`), then copied to every platform:

```bash
flutter test tool/render_icon_test.dart   # writes assets/icon/icon.png + foreground.png
dart run flutter_launcher_icons
```

---

## 🔔 Push server (website reminders)

Browsers can't schedule a notification for later, so the website registers its push subscription with a small [Cloudflare Worker](push-server/src/index.js). Every minute the Worker looks for reminders that are due and sends each one a random quote from the chosen holy book over Web Push. It's free on Cloudflare's free plan.

| Part | File |
| --- | --- |
| Worker (HTTP API + every-minute cron) | `push-server/src/index.js` |
| Choosing a quote from the chosen book | `push-server/src/quotes.js` |
| Web Push encryption + VAPID signing | `push-server/src/webpush.js` |
| Time-zone / daylight-saving maths | `push-server/src/time.js` |
| Database table | `push-server/schema.sql` |
| Quotes sent in notifications | `push-server/src/quotes.json` (generated, see below) |
| Browser side | `web/push_sw.js`, `web/history_db.js`, `lib/services/web_push/` |

Databases created before the holy-book choice existed need one migration: `npm run db:migrate` (already run on the live database).

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
npm test                                            # encryption, VAPID, time-zone and quote tests
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
├── main.dart                         # App entry, first-run welcome
├── app_scope.dart                    # Gives screens the stores and services
├── theme.dart                        # Paper & terracotta palette (light + dark), fonts
├── models/quote.dart                 # Quote + ScriptureSource
├── data/quotes.dart                  # The 60 quotes, daily pick, reflection prompts
├── services/
│   ├── settings_store.dart           # Reminder settings, welcome seen
│   ├── library_store.dart            # Name, saved, reflections, history (on device)
│   ├── notification_service.dart     # Daily messages (mobile + web) and history
│   ├── reminder_types.dart
│   └── web_push/                     # Web Push client (web) + stub (mobile)
├── screens/
│   ├── welcome_screen.dart
│   ├── app_shell.dart                # Tabs, bottom bar, side menu
│   ├── home_tab.dart                 # Today's message card
│   ├── history_tab.dart              # Received / Saved
│   ├── profile_tab.dart              # Name, counts, settings
│   └── message_screen.dart           # Full message + reflection
└── widgets/
    ├── common.dart                   # Header, cards, buttons, sharing
    ├── illustrations.dart            # Leaves, book, hills, quote marks (drawn in code)
    └── reminder_sheet.dart           # Time + holy book picker, iPhone help
web/push_sw.js                        # Service worker: push, notification taps, offline
web/history_db.js                     # Received-message history (IndexedDB)
push-server/                          # Cloudflare Worker that sends web reminders
tool/export_quotes.dart               # Copies quotes to the push server
tool/render_icon_test.dart            # Draws the app icon
test/                                 # Flutter tests
```
