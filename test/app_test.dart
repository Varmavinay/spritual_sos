import 'package:divine_quotes/data/quotes.dart';
import 'package:divine_quotes/main.dart';
import 'package:divine_quotes/models/quote.dart';
import 'package:divine_quotes/services/library_store.dart';
import 'package:divine_quotes/services/notification_service.dart';
import 'package:divine_quotes/services/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reminders that "work" without a device or browser.
class _FakeNotifications extends NotificationService {
  _FakeNotifications(this.settings, LibraryStore library, this._availability)
      : super(settings, library);

  final SettingsStore settings;
  final ReminderAvailability _availability;

  @override
  ReminderAvailability get availability => _availability;

  @override
  Future<void> init() async {}

  @override
  Future<void> refreshHistory() async {}

  @override
  Future<PermissionResult> enable(TimeOfDay time, ScriptureSource? source) async {
    await settings.setNotificationTime(time);
    await settings.setNotificationSource(source);
    await settings.setNotificationsEnabled(true);
    notifyListeners();
    return PermissionResult.granted;
  }
}

late LibraryStore library;
late SettingsStore settings;

Future<void> _pump(
  WidgetTester tester, {
  bool welcomed = true,
  ReminderAvailability availability = ReminderAvailability.available,
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({'welcome_seen': welcomed});
  settings = await SettingsStore.load();
  library = LibraryStore(settings.prefs);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(SpiritualSosApp(
    settings: settings,
    library: library,
    notifications: _FakeNotifications(settings, library, availability),
  ));
  await tester.pumpAndSettle();
}

/// Scrolls [text] into view and taps it.
Future<void> _tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(text), 200,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
}

void main() {
  // Fonts are fetched at runtime in the app; tests use the fallback font.
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('GoogleFonts')) return;
    FlutterError.presentError(details);
    throw details.exception;
  };

  testWidgets('first launch shows the welcome screen, then today’s message',
      (tester) async {
    await _pump(tester, welcomed: false);
    expect(find.text('Small words. A little more light.'), findsOneWidget);

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY’S MESSAGE'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(settings.welcomeSeen, isTrue);
  });

  testWidgets('saved messages show in History and on the profile',
      (tester) async {
    await _pump(tester);
    final today = dailyQuote(DateTime.now());

    await _tapText(tester, 'Save');
    await tester.pumpAndSettle();
    expect(library.isSaved(today), isTrue);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    expect(find.text('${today.citation} · ${today.source.displayName}'),
        findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Saved messages'), findsOneWidget);
  });

  testWidgets('the daily message asks for a time and a holy book',
      (tester) async {
    await _pump(tester);

    await _tapText(tester, 'Get a daily message');
    await tester.pumpAndSettle();
    expect(find.text('FROM WHICH HOLY BOOK?'), findsOneWidget);
    expect(find.text('All three'), findsOneWidget);

    await tester.tap(find.text('The Bhagavad Gita'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Turn on daily message');
    await tester.pumpAndSettle();

    expect(settings.notificationsEnabled, isTrue);
    expect(settings.notificationSource, ScriptureSource.gita);
    expect(find.text('8:00 AM · Bhagavad Gita'), findsOneWidget);
  });

  testWidgets('received messages open in full with a reflection',
      (tester) async {
    await _pump(tester);
    final quote = quoteById(42)!;
    library.addDeliveries(
        [Delivery(quote, DateTime.now().subtract(const Duration(days: 1)))]);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('YESTERDAY'), findsOneWidget);

    await tester.tap(find.text(quote.text));
    await tester.pumpAndSettle();
    expect(find.text('Reflection'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Breathe first.');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(library.reflection(quote), 'Breathe first.');

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(library.isSaved(quote), isTrue);
  });

  testWidgets('the username can be edited on the profile', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Vinay ');
    await tester.tap(find.byTooltip('Save name'));
    await tester.pumpAndSettle();

    expect(library.userName, 'Vinay');
    expect(find.text('Vinay'), findsOneWidget);
  });

  testWidgets('wide screens get the desktop website', (tester) async {
    await _pump(tester, size: const Size(1440, 900));
    expect(find.text('Wisdom from every tradition'), findsOneWidget);
    expect(find.text('Home'), findsNothing); // No phone tab bar.

    await tester.tap(find.text('Daily message'));
    await tester.pumpAndSettle();
    expect(find.text('FROM WHICH HOLY BOOK?'), findsOneWidget);
    await tester.tap(find.text('The Quran').last);
    await tester.tap(find.text('Turn on daily message'));
    await tester.pumpAndSettle();
    expect(settings.notificationSource, ScriptureSource.quran);

    await tester.tap(find.text('Saved').first);
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('iPhone Safari explains Add to Home Screen', (tester) async {
    await _pump(tester, availability: ReminderAvailability.needsHomeScreen);

    await _tapText(tester, 'Get a daily message');
    await tester.pumpAndSettle();
    expect(find.text('Choose “Add to Home Screen”'), findsOneWidget);
    expect(find.text('Turn on daily message'), findsNothing);
  });
}
