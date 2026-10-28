import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

/// Preferences kept on this device: the daily reminder and
/// whether the welcome screen has been seen.
class SettingsStore {
  SettingsStore(this.prefs);

  static const _enabledKey = 'notifications_enabled';
  static const _hourKey = 'notification_hour';
  static const _minuteKey = 'notification_minute';
  static const _sourceKey = 'notification_source';
  static const _welcomedKey = 'welcome_seen';

  final SharedPreferences prefs;

  static Future<SettingsStore> load() async =>
      SettingsStore(await SharedPreferences.getInstance());

  bool get notificationsEnabled => prefs.getBool(_enabledKey) ?? false;
  Future<void> setNotificationsEnabled(bool value) =>
      prefs.setBool(_enabledKey, value);

  TimeOfDay get notificationTime => TimeOfDay(
        hour: prefs.getInt(_hourKey) ?? 8,
        minute: prefs.getInt(_minuteKey) ?? 0,
      );
  Future<void> setNotificationTime(TimeOfDay time) => Future.wait([
        prefs.setInt(_hourKey, time.hour),
        prefs.setInt(_minuteKey, time.minute),
      ]);

  /// Which holy book reminders come from; null means all three at random.
  ScriptureSource? get notificationSource =>
      ScriptureSource.fromName(prefs.getString(_sourceKey));
  Future<void> setNotificationSource(ScriptureSource? source) =>
      prefs.setString(_sourceKey, source?.name ?? 'all');

  bool get welcomeSeen => prefs.getBool(_welcomedKey) ?? false;
  Future<void> setWelcomeSeen() => prefs.setBool(_welcomedKey, true);
}
