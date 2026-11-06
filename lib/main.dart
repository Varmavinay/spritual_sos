import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/app_shell.dart';
import 'screens/faith_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/library_store.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';
import 'theme.dart';
import 'widgets/common.dart';

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
        // Wide screens get the full desktop website; on tablets the phone
        // layout stays in a centred column.
        builder: (context, child) => isDesktop(context)
            ? child!
            : ColoredBox(
                color: SosColors.of(context).paper,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: child,
                  ),
                ),
              ),
        home: !settings.welcomeSeen
            ? const _Welcome()
            : settings.faith == null
                ? const _AskFaith()
                : const AppShell(),
      ),
    );
  }
}

Route<void> _fadeTo(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// First launch: the welcome screen, then the faith question.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onBegin: () {
        AppScope.of(context).settings.setWelcomeSeen();
        Navigator.of(context).pushReplacement(_fadeTo(const _AskFaith()));
      },
    );
  }
}

/// Asked once; also shown to people who used the app before the question
/// existed.
class _AskFaith extends StatelessWidget {
  const _AskFaith();

  @override
  Widget build(BuildContext context) {
    return FaithScreen(
      onDone: () => Navigator.of(context).pushReplacement(_fadeTo(const AppShell())),
    );
  }
}
