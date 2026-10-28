/// Whether daily reminders can be offered on this device.
enum ReminderAvailability {
  /// Reminders work here.
  available,

  /// iPhone/iPad Safari: Web Push only works after "Add to Home Screen".
  needsHomeScreen,

  /// This browser or platform cannot show notifications.
  unsupported,
}

enum PermissionResult { granted, denied, unsupported, serverError }
