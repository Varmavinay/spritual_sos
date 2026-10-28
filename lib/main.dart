import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/app_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/library_store.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final library = LibraryStore(settings.prefs);
  final notifications = NotificationService(settings, library);
  runApp(SpiritualSosApp(
    settings: settings,
    library: library,
    notifications: notifications,
  ));
  // Set up reminders after the first frame so they never delay start-up
  // (time-zone data, scheduling, or waiting for the browser's service worker).
  notifications.init();
}

class SpiritualSosApp extends StatelessWidget {
  const SpiritualSosApp({
    super.key,
    required this.settings,
    required this.library,
    required this.notifications,
  });

  final SettingsStore settings;
  final LibraryStore library;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      library: library,
      notifications: notifications,
      child: MaterialApp(
        title: 'Spiritual SOS',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        // On tablets and desktop browsers, keep the phone-sized layout in a
        // centred column.
        builder: (context, child) => ColoredBox(
          color: SosColors.of(context).paper,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child,
            ),
          ),
        ),
        home: settings.welcomeSeen ? const AppShell() : const _FirstRun(),
      ),
    );
  }
}

class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onBegin: () {
        AppScope.of(context).settings.setWelcomeSeen();
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const AppShell(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ));
      },
    );
  }
}
