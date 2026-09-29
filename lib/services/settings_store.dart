import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the daily-notification preferences on the device.
class SettingsStore {
  SettingsStore._(this._prefs);

  static const _enabledKey = 'notifications_enabled';
  static const _hourKey = 'notification_hour';
  static const _minuteKey = 'notification_minute';
  static const _lastSentKey = 'last_notification_date';

  final SharedPreferences _prefs;

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  bool get notificationsEnabled => _prefs.getBool(_enabledKey) ?? false;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_enabledKey, value);

  TimeOfDay get notificationTime => TimeOfDay(
        hour: _prefs.getInt(_hourKey) ?? 8,
        minute: _prefs.getInt(_minuteKey) ?? 0,
      );
  Future<void> setNotificationTime(TimeOfDay time) async {
    await _prefs.setInt(_hourKey, time.hour);
    await _prefs.setInt(_minuteKey, time.minute);
  }

  /// Date (yyyy-m-d) of the last notification shown by the web checker.
  String? get lastSentDate => _prefs.getString(_lastSentKey);
  Future<void> setLastSentDate(String value) =>
      _prefs.setString(_lastSentKey, value);
}
