import 'package:divine_quotes/screens/home_screen.dart';
import 'package:divine_quotes/services/notification_service.dart';
import 'package:divine_quotes/services/settings_store.dart';
import 'package:divine_quotes/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications extends NotificationService {
  _FakeNotifications(super.settings, this._availability);

  final ReminderAvailability _availability;

  @override
  ReminderAvailability get availability => _availability;
}

Future<void> _pump(WidgetTester tester, ReminderAvailability availability,
    {Size size = const Size(360, 780)}) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsStore.load();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: lightTheme,
    home: HomeScreen(notifications: _FakeNotifications(settings, availability)),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  // Fonts are fetched at runtime in the app; tests use the fallback font.
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('GoogleFonts')) return;
    FlutterError.presentError(details);
    throw details.exception;
  };

  testWidgets('shows a quote, filters and the reminder toggle on a small phone',
      (tester) async {
    await _pump(tester, ReminderAvailability.available);

    expect(find.text('Sacred Wisdom'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
    expect(find.byType(Switch), findsOneWidget);

    await tester.scrollUntilVisible(find.text('☪️ Quran'), -200);
    await tester.tap(find.text('☪️ Quran'));
    await tester.pumpAndSettle();
    expect(find.text('QURAN'), findsOneWidget);

    await tester.ensureVisible(find.text('New quote'));
    await tester.tap(find.text('New quote'));
    await tester.pumpAndSettle();
    expect(find.text('QURAN'), findsOneWidget);
  });

  testWidgets('iPhone Safari explains Add to Home Screen instead of a toggle',
      (tester) async {
    await _pump(tester, ReminderAvailability.needsHomeScreen);

    await tester.scrollUntilVisible(
        find.text('Get daily reminders on iPhone'), 200);
    await tester.scrollUntilVisible(
        find.text('Choose “Add to Home Screen”'), 100);
    expect(find.byType(Switch), findsNothing);
  });
}
