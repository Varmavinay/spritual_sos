import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/quotes.dart';
import '../models/quote.dart';
import 'library_store.dart';
import 'reminder_types.dart';
import 'settings_store.dart';
import 'web_push/web_push.dart';

export 'reminder_types.dart';

/// Daily quote reminders.
///
/// - Android / iOS: the next [_daysAhead] days are scheduled with the OS, each
///   with a different quote from the chosen holy book, and topped up every
///   time the app starts. Reminders whose time has passed go into the
///   history.
/// - Web: the browser's push subscription is registered with the push server
///   (push-server/), which sends the quote at the chosen time even when the
///   site is closed. The service worker records what it shows.
class NotificationService extends ChangeNotifier {
  NotificationService(this._settings, this._library, {WebPush? webPush})
      : _webPush = webPush ?? WebPush();

  static const _daysAhead = 30;
  static const _scheduledKey = 'scheduled_reminders';

  final SettingsStore _settings;
  final LibraryStore _library;
  final WebPush _webPush;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _mobileReady = false;
  Future<void>? _initFuture;

  /// Set to a quote id when a reminder is tapped; the UI opens it and
  /// clears it.
  final ValueNotifier<int?> openRequest = ValueNotifier(null);

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

  /// The holy book reminders come from; null means all three at random.
  ScriptureSource? get source => _settings.notificationSource;

  /// Runs after the app is on screen; listeners are told if the saved
  /// reminder state changes. Safe to call more than once.
  Future<void> init() => _initFuture ??= _init();

  /// Mobile actions wait for [init] in case the user taps before it is done.
  Future<void> get _mobileInitDone => _initFuture ?? init();

  Future<void> _init() async {
    if (kIsWeb) {
      _webPush.listen(
        onOpenQuote: (id) => openRequest.value = id,
        onDelivered: refreshHistory,
      );
      if (_webPush.takeLaunchQuoteId() case final id?) openRequest.value = id;
      await refreshHistory();
      if (!enabled) return;
      // Keep the saved setting honest: the user may have revoked permission
      // or the browser may have dropped the subscription.
      if (!await _webPush.isSubscribed()) {
        await _settings.setNotificationsEnabled(false);
        notifyListeners();
        return;
      }
      _webPush.sync(time, source); // Refresh time zone; no need to wait.
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
            onDidReceiveNotificationResponse: (response) =>
                _openPayload(response.payload),
          ) ??
          false;
      if (_mobileReady) {
        final launch = await _plugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _openPayload(launch!.notificationResponse?.payload);
        }
      }
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
    await refreshHistory();
    if (enabled) await _scheduleMobile();
  }

  void _openPayload(String? payload) {
    final id = int.tryParse(payload ?? '');
    if (id != null) openRequest.value = id;
  }

  /// Moves reminders that have been delivered into the history.
  Future<void> refreshHistory() async {
    if (kIsWeb) {
      final items = await _webPush.deliveries();
      _library.addDeliveries([
        for (final item in items)
          if (quoteById(item.id) case final quote?)
            Delivery(quote, DateTime.fromMillisecondsSinceEpoch(item.at)),
      ]);
      return;
    }
    final now = DateTime.now();
    final scheduled = _readScheduled();
    final delivered = scheduled.where((d) => !d.at.isAfter(now)).toList();
    if (delivered.isEmpty) return;
    _library.addDeliveries(delivered);
    await _writeScheduled(scheduled.where((d) => d.at.isAfter(now)));
  }

  /// Turns reminders on for [time] from [source] (null: all three).
  /// Must be called directly from a tap (no `await` before it) so browsers
  /// allow the permission prompt.
  Future<PermissionResult> enable(TimeOfDay time, ScriptureSource? source) async {
    // Saved before anything is awaited; SharedPreferences updates its
    // in-memory copy straight away.
    final saved = Future.wait([
      _settings.setNotificationTime(time),
      _settings.setNotificationSource(source),
    ]);
    final result = kIsWeb
        ? await _webPush.enable(time, source)
        : await _enableMobile();
    await saved;
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
      await refreshHistory();
      if (_mobileReady) await _plugin.cancelAll();
      await _writeScheduled(const []);
    }
  }

  /// Changes the time or holy book of reminders that are already on.
  /// Returns false if the change could not be saved on the push server (web).
  Future<bool> update(TimeOfDay time, ScriptureSource? source) async {
    await Future.wait([
      _settings.setNotificationTime(time),
      _settings.setNotificationSource(source),
    ]);
    notifyListeners();
    if (!enabled) return true;
    if (kIsWeb) return _webPush.sync(time, source);
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
    await refreshHistory();
    await _plugin.cancelAll();
    if (!enabled) {
      await _writeScheduled(const []);
      return;
    }

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

    final scheduled = <Delivery>[];
    Quote? previous;
    for (var day = 0; day < _daysAhead; day++) {
      final quote = randomQuote(source: source, excluding: previous);
      previous = quote;
      final at = tz.TZDateTime(tz.local, first.year, first.month,
          first.day + day, reminder.hour, reminder.minute);
      final body = '“${quote.text}”\n— ${quote.citation}';
      await _plugin.zonedSchedule(
        id: day,
        scheduledDate: at,
        title: 'From ${quote.source.withArticle}',
        body: body,
        payload: '${quote.id}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_quote',
            'Daily message',
            channelDescription: 'A daily message from the holy books',
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
      );
      scheduled.add(Delivery(quote, at));
    }
    await _writeScheduled(scheduled);
  }

  List<Delivery> _readScheduled() {
    final raw = _settings.prefs.getString(_scheduledKey);
    if (raw == null) return [];
    try {
      return [
        for (final item in jsonDecode(raw) as List) ?Delivery.fromJson(item),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeScheduled(Iterable<Delivery> deliveries) =>
      _settings.prefs.setString(
          _scheduledKey, jsonEncode([for (final d in deliveries) d.toJson()]));

  @override
  void dispose() {
    openRequest.dispose();
    super.dispose();
  }
}
