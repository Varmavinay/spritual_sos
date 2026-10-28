import 'package:flutter/material.dart';

import '../../models/quote.dart';
import '../reminder_types.dart';

class WebPush {
  ReminderAvailability get availability => ReminderAvailability.unsupported;

  Future<PermissionResult> enable(TimeOfDay time, ScriptureSource? source) async =>
      PermissionResult.unsupported;

  Future<bool> sync(TimeOfDay time, ScriptureSource? source) async => false;

  Future<bool> isSubscribed() async => false;

  Future<void> disable() async {}

  Future<List<({int id, int at})>> deliveries() async => const [];

  int? takeLaunchQuoteId() => null;

  void listen({
    required void Function(int id) onOpenQuote,
    required VoidCallback onDelivered,
  }) {}
}
