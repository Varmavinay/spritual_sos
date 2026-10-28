import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'common.dart';

/// Opens the daily-message settings: the time, and which holy book the
/// message comes from. A bottom sheet on phones, a dialog on desktop.
Future<void> showReminderSheet(BuildContext context) {
  if (isDesktop(context)) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Padding(
            padding: EdgeInsets.only(top: 28),
            child: _ReminderSheet(),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => const _ReminderSheet(),
  );
}

/// One-line summary such as "7:00 AM · Bhagavad Gita".
String reminderSummary(BuildContext context, NotificationService service) {
  final from = service.source?.displayName ?? 'All three';
  return '${service.time.format(context)} · $from';
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet();

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late final NotificationService _service = AppScope.of(context).notifications;
  late TimeOfDay _time = _service.time;
  late ScriptureSource? _source = _service.source;
  bool _busy = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Daily message time',
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  // Not async before calling enable(): browsers only allow the permission
  // prompt while handling the tap itself.
  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final time = _time.format(context);
    setState(() => _busy = true);

    void done(String message, {bool close = true}) {
      if (mounted) setState(() => _busy = false);
      if (close && mounted) navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    if (_service.enabled) {
      _service.update(_time, _source).then((ok) => ok
          ? done('Your daily message will arrive at $time')
          : done('Couldn’t update the reminder. Please try again.',
              close: false));
      return;
    }
    _service.enable(_time, _source).then((result) => switch (result) {
          PermissionResult.granted =>
            done('You’ll get a message every day at $time'),
          PermissionResult.denied => done(
              'Notifications are blocked. Allow them in your settings, then try again.',
              close: false),
          PermissionResult.unsupported =>
            done('Notifications aren’t supported on this device.'),
          PermissionResult.serverError => done(
              'Couldn’t reach the reminder service. Check your connection and try again.',
              close: false),
        });
  }

  void _turnOff() {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    _service.disable().then((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Daily message turned off')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daily message', style: serif(fontSize: 30, color: c.ink)),
          const SizedBox(height: 4),
          Text('A few words from the holy books, once a day.',
              style: TextStyle(color: c.muted, fontSize: 15)),
          const SizedBox(height: 22),
          switch (_service.availability) {
            ReminderAvailability.available => _controls(context),
            ReminderAvailability.needsHomeScreen => const AddToHomeScreenHelp(),
            ReminderAvailability.unsupported => Text(
                'This browser can’t show daily messages. Try Chrome, Edge, '
                'Firefox or Safari, or install the app.',
                style: TextStyle(color: c.muted, fontSize: 15, height: 1.4),
              ),
          },
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final c = SosColors.of(context);
    final on = _service.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TIME', style: eyebrow(c.muted)),
        const SizedBox(height: 10),
        PaperCard(
          onTap: _busy ? null : _pickTime,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: c.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(_time.format(context),
                    style: serif(fontSize: 30, color: c.ink, height: 1.1)),
              ),
              Text('Change',
                  style: TextStyle(
                      color: c.accent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('FROM WHICH HOLY BOOK?', style: eyebrow(c.muted)),
        const SizedBox(height: 10),
        _SourceOption(
          title: 'All three',
          subtitle: 'A different book each day, at random',
          selected: _source == null,
          onTap: _busy ? null : () => setState(() => _source = null),
        ),
        for (final source in ScriptureSource.values)
          _SourceOption(
            title: 'The ${source.displayName}',
            subtitle: switch (source) {
              ScriptureSource.bible => 'Psalms, Proverbs, the Gospels and more',
              ScriptureSource.gita => 'Krishna’s counsel to Arjuna',
              ScriptureSource.quran => 'Verses of mercy, patience and hope',
            },
            selected: _source == source,
            onTap: _busy ? null : () => setState(() => _source = source),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: c.onAccent),
                )
              : Text(on ? 'Save changes' : 'Turn on daily message'),
        ),
        if (on) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: _busy ? null : _turnOff,
            child: const Text('Turn off daily message'),
          ),
        ],
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: Material(
          color: selected ? c.blush : c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? c.accent : c.line,
                width: selected ? 1.4 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: serif(fontSize: 20, color: c.ink)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(color: c.muted, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(selected),
                      color: selected ? c.accent : c.line,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iPhone and iPad Safari only allow notifications for sites added to the
/// Home Screen.
class AddToHomeScreenHelp extends StatelessWidget {
  const AddToHomeScreenHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);

    Widget step(String number, Widget content) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: c.accent,
                child: Text(number,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.onAccent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 15, color: c.ink, height: 1.4),
                  child: content,
                ),
              ),
            ],
          ),
        );

    return PaperCard(
      color: c.blush,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get daily messages on iPhone',
              style: serif(fontSize: 22, color: c.ink)),
          const SizedBox(height: 14),
          step(
            '1',
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Tap the Share button '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.ios_share, size: 18, color: c.accent),
              ),
              const TextSpan(text: ' in Safari'),
            ])),
          ),
          step('2', const Text('Choose “Add to Home Screen”')),
          step('3',
              const Text('Open Spiritual SOS from your Home Screen and turn on the daily message')),
          Text('Needs iOS 16.4 or later.',
              style: TextStyle(color: c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
