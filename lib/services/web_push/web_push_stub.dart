import 'package:flutter/material.dart';

import '../reminder_types.dart';

class WebPush {
  ReminderAvailability get availability => ReminderAvailability.unsupported;

  Future<PermissionResult> enable(TimeOfDay time) async =>
      PermissionResult.unsupported;

  Future<bool> sync(TimeOfDay time) async => false;

  Future<bool> isSubscribed() async => false;

  Future<void> disable() async {}
}
