import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/settings_store.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({
    super.key,
    required this.settings,
    required this.notifications,
    required this.onMessage,
  });

  final SettingsStore settings;
  final NotificationService notifications;
  final ValueChanged<String> onMessage;

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  late bool _enabled = widget.settings.notificationsEnabled;
  late TimeOfDay _time = widget.settings.notificationTime;
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    if (value) {
      final result = await widget.notifications.requestPermission();
      switch (result) {
        case PermissionResult.granted:
          await widget.notifications.setEnabled(true);
          _enabled = true;
          widget.onMessage('Daily notifications enabled!');
        case PermissionResult.denied:
          await widget.notifications.setEnabled(false);
          _enabled = false;
          widget.onMessage(
              'Permission denied. Please allow notifications in settings.');
        case PermissionResult.unsupported:
          await widget.notifications.setEnabled(false);
          _enabled = false;
          widget.onMessage('Notifications are not supported here.');
      }
    } else {
      await widget.notifications.setEnabled(false);
      _enabled = false;
      widget.onMessage('Daily notifications disabled');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    await widget.notifications.setTime(picked);
    if (mounted) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('🔔 Daily Notifications')),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close settings',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Receive an uplifting quote from the sacred scriptures at your '
            'chosen time each day.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Daily Quotes',
                style: TextStyle(fontWeight: FontWeight.w600)),
            value: _enabled,
            onChanged: _busy ? null : _toggle,
          ),
          if (_enabled) ...[
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_time.format(context),
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                onPressed: _pickTime,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily notification scheduled at ${_time.format(context)}',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
