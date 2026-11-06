import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/faith.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reminder_sheet.dart';

/// Asks the user's religion. Shown once, the first time the app opens; the
/// answer becomes the default holy book everywhere, including the daily
/// message.
class FaithScreen extends StatefulWidget {
  const FaithScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<FaithScreen> createState() => _FaithScreenState();
}

class _FaithScreenState extends State<FaithScreen> {
  Faith? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    final faith = _selected;
    if (faith == null) return;
    setState(() => _saving = true);
    await AppScope.of(context).notifications.setFaith(faith);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LeafSprig(width: 64, height: 92, leaves: 5)),
                  const SizedBox(height: 18),
                  Text('Which path is yours?',
                      textAlign: TextAlign.center,
                      style: serif(fontSize: 36, color: c.ink, height: 1.1)),
                  const SizedBox(height: 14),
                  const Center(child: AccentRule(width: 36)),
                  const SizedBox(height: 14),
                  Text(
                    'Your messages and daily notifications will come from your '
                    'holy book. You can still explore the others at any time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.5, color: c.muted, height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  FaithOptions(
                    selected: _selected,
                    onSelected: _saving ? null : (f) => setState(() => _selected = f),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _selected == null || _saving ? null : _continue,
                    child: _saving
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: c.onAccent),
                          )
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: 12),
                  Text('You can change this later in Profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: c.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The five choices: Christian, Hindu, Muslim, Sikh, or no particular
/// religion.
class FaithOptions extends StatelessWidget {
  const FaithOptions({super.key, required this.selected, required this.onSelected});

  final Faith? selected;
  final ValueChanged<Faith>? onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final faith in Faith.values)
            ChoiceTile(
              title: faith.label,
              subtitle: faith.description,
              selected: faith == selected,
              onTap: onSelected == null ? null : () => onSelected!(faith),
            ),
        ],
      );
}

/// Lets the user change their faith from the profile.
Future<void> showFaithPicker(BuildContext context) {
  final service = AppScope.of(context).notifications;
  final messenger = ScaffoldMessenger.of(context);

  Widget content(BuildContext sheetContext) {
    final c = SosColors.of(sheetContext);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.viewPaddingOf(sheetContext).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your faith', style: serif(fontSize: 30, color: c.ink)),
          const SizedBox(height: 4),
          Text('Messages and daily notifications come from this holy book.',
              style: TextStyle(color: c.muted, fontSize: 15)),
          const SizedBox(height: 20),
          FaithOptions(
            selected: service.faith,
            onSelected: (faith) {
              Navigator.of(sheetContext).pop();
              service.setFaith(faith).then((ok) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(ok
                        ? (faith.book == null
                            ? 'You’ll see messages from all four holy books'
                            : 'You’ll see messages from ${faith.book!.withArticle}')
                        : 'Saved, but the reminder service couldn’t be updated. Please try again.'),
                  ));
              });
            },
          ),
        ],
      ),
    );
  }

  if (isDesktop(context)) {
    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.only(top: 28),
            child: content(dialogContext),
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
    builder: content,
  );
}
