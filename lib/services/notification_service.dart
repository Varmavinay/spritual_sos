import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/quotes.dart';
import 'reminder_types.dart';
import 'settings_store.dart';
import 'web_push/web_push.dart';

export 'reminder_types.dart';

/// Daily quote reminders.
///
/// - Android / iOS: the next [_daysAhead] days are scheduled with the OS, each
///   with a different quote, and topped up every time the app starts.
/// - Web: the browser's push subscription is registered with the push server
///   (push-server/), which sends the quote at the chosen time even when the
///   site is closed.
class NotificationService extends ChangeNotifier {
  NotificationService(this._settings, {WebPush? webPush})
      : _webPush = webPush ?? WebPush();

  static const _daysAhead = 30;

  final SettingsStore _settings;
  final WebPush _webPush;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _mobileReady = false;
  Future<void>? _initFuture;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  ReminderAvailability get availability {
    if (kIsWeb) return _webPush.availability;
    return _isMobile
        ? ReminderAvailability.available
        : ReminderAvailability.unsupported;
  }

  bool get enabled => _settings.notificationsEnabled;
  TimeOfDay get time => _settings.notificationTime;

  /// Runs after the app is on screen; listeners are told if the saved
  /// reminder state changes. Safe to call more than once.
  Future<void> init() => _initFuture ??= _init();

  /// Mobile actions wait for [init] in case the user taps before it is done.
  Future<void> get _mobileInitDone => _initFuture ?? init();

  Future<void> _init() async {
    if (kIsWeb) {
      if (!enabled) return;
      // Keep the saved setting honest: the user may have revoked permission
      // or the browser may have dropped the subscription.
      if (!await _webPush.isSubscribed()) {
        await _settings.setNotificationsEnabled(false);
        notifyListeners();
        return;
      }
      _webPush.sync(time); // Refresh time zone; no need to wait.
      return;
    }
    if (!_isMobile) return;

    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      _mobileReady = await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
          ) ??
          false;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
    if (enabled) await _scheduleMobile();
  }

  /// Turns reminders on. Must be called directly from a tap (no `await`
  /// before it) so browsers allow the permission prompt.
  Future<PermissionResult> enable() async {
    final result = kIsWeb
        ? await _webPush.enable(time)
        : await _enableMobile();
    await _settings.setNotificationsEnabled(result == PermissionResult.granted);
    notifyListeners();
    return result;
  }

  Future<void> disable() async {
    await _settings.setNotificationsEnabled(false);
    notifyListeners();
    if (kIsWeb) {
      await _webPush.disable();
    } else {
      await _mobileInitDone;
      if (_mobileReady) await _plugin.cancelAll();
    }
  }

  /// Changes the reminder time. Returns false if the new time could not be
  /// saved on the push server (web only).
  Future<bool> setTime(TimeOfDay value) async {
    await _settings.setNotificationTime(value);
    notifyListeners();
    if (!enabled) return true;
    if (kIsWeb) return _webPush.sync(value);
    await _mobileInitDone;
    await _scheduleMobile();
    return true;
  }

  Future<PermissionResult> _enableMobile() async {
    if (!_isMobile) return PermissionResult.unsupported;
    await _mobileInitDone;
    if (!_mobileReady) return PermissionResult.unsupported;
    bool? granted;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      granted = await android?.requestNotificationsPermission();
      // Exact alarms deliver on the minute; without them Android may delay
      // reminders while the phone is idle. Ask once, but work either way.
      if (granted == true &&
          await android?.canScheduleExactNotifications() == false) {
        await android?.requestExactAlarmsPermission();
      }
    } else {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (granted != true) return PermissionResult.denied;
    await _settings.setNotificationsEnabled(true);
    await _scheduleMobile();
    return PermissionResult.granted;
  }

  Future<void> _scheduleMobile() async {
    if (!_mobileReady) return;
    await _plugin.cancelAll();
    if (!enabled) return;

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final canExact = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      if (canExact == true) scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    final reminder = time;
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, reminder.hour, reminder.minute);
    // Never fire straight away: if today's time has passed, start tomorrow.
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    for (var day = 0; day < _daysAhead; day++) {
      final quote = randomQuote();
      final body = '“${quote.text}”\n— ${quote.citation}';
      await _plugin.zonedSchedule(
        id: day,
        scheduledDate: tz.TZDateTime(tz.local, first.year, first.month,
            first.day + day, reminder.hour, reminder.minute),
        title: '${quote.source.emoji} ${quote.source.displayName}',
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_quote',
            'Daily quote',
            channelDescription: 'A daily quote from the sacred scriptures',
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
      );
    }
  }
}
