import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../../models/quote.dart';
import '../reminder_types.dart';

/// URL of the push server in push-server/ (a Cloudflare Worker).
/// Override at build time with --dart-define=PUSH_SERVER_URL=...
const pushServerUrl = String.fromEnvironment(
  'PUSH_SERVER_URL',
  defaultValue: 'https://divine-quotes-push.varmavinay.workers.dev',
);

/// Daily reminders on the web via Web Push.
///
/// Browsers cannot schedule notifications themselves, so the browser's push
/// subscription is registered with the push server, which sends the quote at
/// the chosen time even when the site is closed. On iPhone this needs iOS
/// 16.4+ and the site added to the Home Screen.
///
/// The service worker (web/push_sw.js) records every reminder it shows in
/// IndexedDB (web/history_db.js), which [deliveries] reads for the history.
class WebPush {
  ReminderAvailability get availability {
    if (_isIos && !_isStandalone) return ReminderAvailability.needsHomeScreen;
    final supported = web.window.has('Notification') &&
        web.window.has('PushManager') &&
        web.window.navigator.has('serviceWorker');
    return supported
        ? ReminderAvailability.available
        : ReminderAvailability.unsupported;
  }

  /// Asks for permission, subscribes this browser and registers it with the
  /// push server. Call straight from a tap: Safari only shows the permission
  /// prompt during a user gesture, so it is requested before any `await`.
  Future<PermissionResult> enable(TimeOfDay time, ScriptureSource? source) async {
    if (availability != ReminderAvailability.available) {
      return PermissionResult.unsupported;
    }
    final permission =
        (await web.Notification.requestPermission().toDart).toDart;
    if (permission != 'granted') return PermissionResult.denied;

    try {
      final registration = await _registration();
      var subscription =
          await registration.pushManager.getSubscription().toDart;
      if (subscription == null) {
        final key = await _fetchServerKey();
        subscription = await registration.pushManager
            .subscribe(web.PushSubscriptionOptionsInit(
              userVisibleOnly: true,
              applicationServerKey: key.toJS,
            ))
            .toDart;
      }
      final ok = await _register(subscription, time, source);
      return ok ? PermissionResult.granted : PermissionResult.serverError;
    } catch (e) {
      debugPrint('Web Push subscribe failed: $e');
      return PermissionResult.serverError;
    }
  }

  /// Re-sends the existing subscription (new time or holy book, new time
  /// zone, or simply making sure the server still has it). Returns false if
  /// not subscribed.
  Future<bool> sync(TimeOfDay time, ScriptureSource? source) async {
    try {
      if (web.Notification.permission != 'granted') return false;
      final subscription = await _currentSubscription();
      if (subscription == null) return false;
      return await _register(subscription, time, source);
    } catch (e) {
      debugPrint('Web Push sync failed: $e');
      return false;
    }
  }

  Future<bool> isSubscribed() async {
    try {
      return web.Notification.permission == 'granted' &&
          await _currentSubscription() != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    try {
      final subscription = await _currentSubscription();
      if (subscription == null) return;
      final endpoint = subscription.endpoint;
      await subscription.unsubscribe().toDart;
      await http.post(
        Uri.parse('$pushServerUrl/unsubscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'endpoint': endpoint}),
      );
    } catch (e) {
      debugPrint('Web Push unsubscribe failed: $e');
    }
  }

  /// Reminders the service worker has shown on this browser.
  Future<List<({int id, int at})>> deliveries() async {
    try {
      final history = globalContext.getProperty<JSObject?>('sosHistory'.toJS);
      if (history == null) return const [];
      final raw = await history
          .callMethod<JSPromise<JSString>>('listJson'.toJS)
          .toDart;
      return [
        for (final item in jsonDecode(raw.toDart) as List)
          if (item case {'id': final int id, 'at': final num at})
            (id: id, at: at.toInt()),
      ];
    } catch (e) {
      debugPrint('Reading reminder history failed: $e');
      return const [];
    }
  }

  /// The quote to open when the site was opened from a notification
  /// (`?quote=<id>`). Removes it from the address bar so a reload does not
  /// open it again.
  int? takeLaunchQuoteId() {
    final id = int.tryParse(Uri.base.queryParameters['quote'] ?? '');
    if (id != null) {
      final url = Uri.base.replace(queryParameters: {
        ...Uri.base.queryParameters,
      }..remove('quote'));
      final clean = url.toString().replaceFirst(RegExp(r'\?$'), '');
      web.window.history.replaceState(null, '', clean);
    }
    return id;
  }

  /// Messages from the service worker: a notification was tapped while the
  /// site was already open, or a new reminder arrived.
  void listen({
    required void Function(int id) onOpenQuote,
    required VoidCallback onDelivered,
  }) {
    if (!web.window.navigator.has('serviceWorker')) return;
    web.window.navigator.serviceWorker.addEventListener(
      'message',
      ((web.MessageEvent event) {
        final data = event.data;
        if (data == null || !data.isA<JSObject>()) return;
        final message = data as JSObject;
        final type = message.getProperty<JSAny?>('type'.toJS);
        if (type == null || !type.isA<JSString>()) return;
        switch ((type as JSString).toDart) {
          case 'open-quote':
            final id = message.getProperty<JSAny?>('id'.toJS);
            if (id != null && id.isA<JSNumber>()) {
              onOpenQuote((id as JSNumber).toDartInt);
            }
          case 'delivered':
            onDelivered();
        }
      }).toJS,
    );
  }

  Future<web.PushSubscription?> _currentSubscription() async {
    if (availability != ReminderAvailability.available) return null;
    final registration = await _registration();
    return registration.pushManager.getSubscription().toDart;
  }

  /// The service worker from web/push_sw.js (registered in index.html).
  Future<web.ServiceWorkerRegistration> _registration() =>
      web.window.navigator.serviceWorker.ready.toDart
          .timeout(const Duration(seconds: 10));

  Future<Uint8List> _fetchServerKey() async {
    final response = await http.get(Uri.parse('$pushServerUrl/vapid-public-key'));
    if (response.statusCode != 200) {
      throw StateError('Push server returned ${response.statusCode}');
    }
    final key = (jsonDecode(response.body) as Map)['publicKey'] as String;
    return base64Url.decode(base64Url.normalize(key));
  }

  Future<bool> _register(web.PushSubscription subscription, TimeOfDay time,
      ScriptureSource? source) async {
    final response = await http.post(
      Uri.parse('$pushServerUrl/subscribe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subscription': {
          'endpoint': subscription.endpoint,
          'keys': {
            'p256dh': _key(subscription, 'p256dh'),
            'auth': _key(subscription, 'auth'),
          },
        },
        'hour': time.hour,
        'minute': time.minute,
        'timeZone': _timeZone(),
        'source': source?.name ?? 'all',
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('Push server rejected subscription: ${response.body}');
    }
    return response.statusCode == 200;
  }

  static String _key(web.PushSubscription subscription, String name) {
    final buffer = subscription.getKey(name);
    if (buffer == null) throw StateError('Subscription has no $name key');
    return base64Url
        .encode(buffer.toDart.asUint8List())
        .replaceAll('=', '');
  }

  static String _timeZone() {
    try {
      final intl = globalContext.getProperty<JSObject>('Intl'.toJS);
      final format = intl.callMethod<JSObject>('DateTimeFormat'.toJS);
      final options = format.callMethod<JSObject>('resolvedOptions'.toJS);
      return options.getProperty<JSString>('timeZone'.toJS).toDart;
    } catch (_) {
      return 'UTC';
    }
  }

  static bool get _isIos {
    final nav = web.window.navigator;
    final ua = nav.userAgent;
    // iPadOS reports itself as a Mac, but has touch.
    return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
        (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
  }

  static bool get _isStandalone {
    if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
    final standalone = web.window.navigator.getProperty<JSAny?>('standalone'.toJS);
    return standalone.isA<JSBoolean>() && (standalone as JSBoolean).toDart;
  }
}
