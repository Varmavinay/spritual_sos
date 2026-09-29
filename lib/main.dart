import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final notifications = NotificationService(settings);
  await notifications.init();
  runApp(DivineQuotesApp(settings: settings, notifications: notifications));
}

class DivineQuotesApp extends StatelessWidget {
  const DivineQuotesApp({
    super.key,
    required this.settings,
    required this.notifications,
  });

  final SettingsStore settings;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Quotes',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: HomeScreen(settings: settings, notifications: notifications),
    );
  }
}
