import 'package:flutter/material.dart';

import '../services/notification_service.dart';

/// Daily-reminder controls shown under the quote.
class ReminderCard extends StatefulWidget {
  const ReminderCard({
    super.key,
    required this.notifications,
    required this.onMessage,
  });

  final NotificationService notifications;
  final ValueChanged<String> onMessage;

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool _busy = false;

  NotificationService get _service => widget.notifications;

  // Not async before calling enable(): browsers only allow the permission
  // prompt while handling the tap itself.
  void _toggle(bool on) {
    setState(() => _busy = true);
    final work = on ? _service.enable() : _service.disable().then((_) => null);
    work.then((result) {
      if (!mounted) return;
      setState(() => _busy = false);
      final time = _service.time.format(context);
      widget.onMessage(switch (result) {
        null => 'Daily reminders turned off',
        PermissionResult.granted => 'You’ll get a quote every day at $time',
        PermissionResult.denied =>
          'Notifications are blocked. Allow them in your settings, then try again.',
        PermissionResult.unsupported =>
          'Notifications aren’t supported on this device.',
        PermissionResult.serverError =>
          'Couldn’t reach the reminder service. Check your connection and try again.',
      });
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _service.time,
      helpText: 'Daily reminder time',
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    final ok = await _service.setTime(picked);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onMessage(ok
        ? 'Reminder moved to ${picked.format(context)}'
        : 'Couldn’t update the reminder. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) => switch (_service.availability) {
        ReminderAvailability.available => _buildControls(context),
        ReminderAvailability.needsHomeScreen => const _AddToHomeScreenHelp(),
        ReminderAvailability.unsupported => const _Unsupported(),
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final on = _service.enabled;
    final time = _service.time.format(context);

    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              _IconBadge(
                icon: on ? Icons.notifications_active : Icons.notifications_none,
                highlighted: on,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily reminder',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      on
                          ? 'A new quote every day at $time'
                          : 'Get an uplifting quote each day',
                      style: text.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Switch(
                  value: on,
                  onChanged: _toggle,
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: on
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text('Change time · $time'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _AddToHomeScreenHelp extends StatelessWidget {
  const _AddToHomeScreenHelp();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget step(String number, Widget content) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: scheme.primary,
                child: Text(number,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary)),
              ),
              const SizedBox(width: 10),
              Expanded(child: DefaultTextStyle.merge(
                  style: text.bodyMedium, child: content)),
            ],
          ),
        );

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.notifications_none),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Get daily reminders on iPhone',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          step(
            '1',
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Tap the Share button '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.ios_share, size: 18, color: scheme.primary),
              ),
              const TextSpan(text: ' in Safari'),
            ])),
          ),
          step('2', const Text('Choose “Add to Home Screen”')),
          step('3',
              const Text('Open Divine Quotes from your Home Screen and turn on the daily reminder')),
          const SizedBox(height: 10),
          Text('Needs iOS 16.4 or later.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Panel(
      child: Row(
        children: [
          const _IconBadge(icon: Icons.notifications_off_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'This browser can’t show daily reminders. Try Chrome, Edge, '
              'Firefox or Safari, or install the app.',
              style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.highlighted = false});

  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? scheme.primary : scheme.secondaryContainer,
      ),
      child: Icon(icon,
          size: 22,
          color: highlighted ? scheme.onPrimary : scheme.onSecondaryContainer),
    );
  }
}
