import 'package:flutter/widgets.dart';

import 'services/library_store.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';

/// Gives every screen access to the app's stores and services.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.library,
    required this.notifications,
    required super.child,
  });

  final SettingsStore settings;
  final LibraryStore library;
  final NotificationService notifications;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      settings != old.settings ||
      library != old.library ||
      notifications != old.notifications;
}
