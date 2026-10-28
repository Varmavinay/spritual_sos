import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final notifications = NotificationService(settings);
  runApp(DivineQuotesApp(notifications: notifications));
  // Set up reminders after the first frame so they never delay start-up
  // (time-zone data, scheduling, or waiting for the browser's service worker).
  notifications.init();
}

class DivineQuotesApp extends StatelessWidget {
  const DivineQuotesApp({super.key, required this.notifications});

  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Quotes',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: HomeScreen(notifications: notifications),
    );
  }
}
