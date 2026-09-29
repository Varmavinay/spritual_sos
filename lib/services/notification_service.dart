import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/quotes.dart';
import 'settings_store.dart';

enum PermissionResult { granted, denied, unsupported }

/// Daily quote notifications.
///
/// On Android and iOS the next [_daysAhead] days are scheduled with the OS,
/// each with a different quote, and topped up every time the app starts.
/// Browsers cannot schedule notifications, so on the web a timer checks
/// every 30 seconds while the tab is open (same as the original PWA).
class NotificationService {
  NotificationService(this._settings);

  static const _daysAhead = 30;
  static const _webNotificationId = 0;

  final SettingsStore _settings;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Timer? _webTimer;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether this platform can show notifications at all.
  bool get isSupported => kIsWeb || _isMobile;

  Future<void> init() async {
    if (!isSupported) return;
    try {
      if (_isMobile) {
        tz_data.initializeTimeZones();
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      }
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          web: WebInitializationSettings(),
        ),
      );
      _initialized = ok ?? false;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      _initialized = false;
    }

    if (_settings.notificationsEnabled) await _reschedule();
  }

  Future<PermissionResult> requestPermission() async {
    if (!isSupported || !_initialized) return PermissionResult.unsupported;
    bool? granted;
    if (kIsWeb) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return granted == true ? PermissionResult.granted : PermissionResult.denied;
  }

  Future<void> setEnabled(bool enabled) async {
    await _settings.setNotificationsEnabled(enabled);
    await _reschedule();
  }

  Future<void> setTime(TimeOfDay time) async {
    await _settings.setNotificationTime(time);
    await _reschedule();
  }

  Future<void> _reschedule() async {
    if (!_initialized) return;
    if (kIsWeb) {
      _webTimer?.cancel();
      _webTimer = null;
      if (_settings.notificationsEnabled) {
        _checkWeb();
        _webTimer =
            Timer.periodic(const Duration(seconds: 30), (_) => _checkWeb());
      }
      return;
    }

    await _plugin.cancelAll();
    if (!_settings.notificationsEnabled) return;

    final time = _settings.notificationTime;
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    for (var day = 0; day < _daysAhead; day++) {
      final quote = randomQuote();
      final when = tz.TZDateTime(tz.local, first.year, first.month,
          first.day + day, time.hour, time.minute);
      await _plugin.zonedSchedule(
        id: day,
        scheduledDate: when,
        title: '${quote.source.emoji} ${quote.source.displayName}',
        body: '"${quote.text}"\n— ${quote.citation}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_quote',
            'Daily quote',
            channelDescription: 'A daily quote from the sacred scriptures',
            styleInformation: BigTextStyleInformation(
                '"${quote.text}"\n— ${quote.citation}'),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _checkWeb() async {
    if (!_settings.notificationsEnabled) return;
    final web = _plugin.resolvePlatformSpecificImplementation<
        WebFlutterLocalNotificationsPlugin>();
    if (web == null ||
        web.permissionStatus != WebNotificationPermission.granted) {
      return;
    }

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (_settings.lastSentDate == today) return;

    final time = _settings.notificationTime;
    if (now.hour * 60 + now.minute < time.hour * 60 + time.minute) return;

    await _settings.setLastSentDate(today);
    final quote = randomQuote();
    try {
      await _plugin.show(
        id: _webNotificationId,
        title: '${quote.source.emoji} ${quote.source.displayName}',
        body: '"${quote.text}"\n— ${quote.citation}',
        notificationDetails: const NotificationDetails(
          web: WebNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Web notification failed: $e');
    }
  }
}
