# 🕊️ Divine Quotes – Sacred Wisdom

A Flutter app for **Android, iOS and the web** that shares **60 inspiring quotes** from the **Bible**, **Bhagavad Gita** and **Holy Quran** (20 from each).

This project used to be a vanilla-JS Progressive Web App. It has been rebuilt in Flutter with the same design and features, so one codebase now covers all three platforms.

---

## ✨ Features

- **60 curated sacred quotes** with scripture citations.
- **Random quote** on every launch and each tap of **New Quote**. The same quote never shows twice in a row.
- **Scripture filter:** **All**, ✝️ **Bible**, 🕉️ **Gita** or ☪️ **Quran**.
- **Share** through the native share sheet, or **copy to clipboard**.
- **Daily notifications** at a time you choose, saved on the device:
  - **Android / iOS:** scheduled with the OS for the next 30 days, each day with a different quote. The schedule is topped up every time the app opens, so notifications arrive even when the app is closed.
  - **Web:** browsers can't schedule notifications, so like the original PWA, the page checks every 30 seconds while the tab is open.
- **Light & dark theme** that follows the system setting (Material 3 purple palette from the original app).

---

## 🚀 Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.13+).

```bash
flutter pub get

flutter run -d chrome     # website
flutter run -d android    # Android device / emulator
flutter run -d ios        # iPhone / simulator (needs a Mac with Xcode)
```

### Building releases

```bash
flutter build web --release --base-href /divine-quotes-pwa/   # output: build/web
flutter build apk --release                                    # or: flutter build appbundle
flutter build ipa --release                                    # on macOS
```

Before publishing to the stores:
- Change the Android `applicationId` in `android/app/build.gradle.kts` and the iOS bundle identifier in Xcode (both still use `com.example.*`).
- Set up a release signing config for Android and a development team for iOS.

### App icons

Icons for every platform are generated from `assets/icon/icon.png`:

```bash
dart run flutter_launcher_icons
```

---

## 🌐 Publishing the website on GitHub Pages

`.github/workflows/deploy-web.yml` builds the Flutter web app and deploys it on every push to `main`.

One-time setup: in the repo go to **Settings → Pages → Build and deployment → Source** and choose **GitHub Actions**.

The site will be live at `https://<username>.github.io/divine-quotes-pwa/`.

---

## 📂 Project structure

```
lib/
├── main.dart                               # App entry: loads settings, notifications, theme
├── theme.dart                              # Material 3 light & dark colour schemes
├── models/quote.dart                       # Quote + ScriptureSource
├── data/quotes.dart                        # The 60 quotes + random/filter helpers
├── services/
│   ├── settings_store.dart                 # Saved preferences (shared_preferences)
│   └── notification_service.dart           # Daily notifications (mobile + web)
├── screens/home_screen.dart                # Main screen
└── widgets/
    ├── quote_card.dart                     # Animated gradient quote card
    └── notification_settings_dialog.dart   # Enable toggle + time picker
test/quotes_test.dart                       # Unit tests for quote data
android/  ios/  web/                        # Platform projects
```
