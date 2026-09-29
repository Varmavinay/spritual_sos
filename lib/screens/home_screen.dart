import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quotes.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../services/settings_store.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/quote_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.notifications,
  });

  final SettingsStore settings;
  final NotificationService notifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScriptureSource? _filter;
  late Quote _quote = randomQuote();

  bool get _notificationsOn => widget.settings.notificationsEnabled;

  void _newQuote() =>
      setState(() => _quote = randomQuote(source: _filter, excluding: _quote));

  void _setFilter(ScriptureSource? source) => setState(() {
        _filter = source;
        _quote = randomQuote(source: source, excluding: _quote);
      });

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _quote.shareText));
    _showMessage('Quote copied to clipboard!');
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text: _quote.shareText,
        subject: '${_quote.source.displayName} Quote',
        // Needed for the iPad share popover.
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (_) {
      await _copy();
    }
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => NotificationSettingsDialog(
        settings: widget.settings,
        notifications: widget.notifications,
        onMessage: _showMessage,
      ),
    );
    setState(() {}); // Refresh bell + hint banner.
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showNotificationUi = widget.notifications.isSupported;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacred Wisdom',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (showNotificationUi)
            IconButton(
              tooltip: 'Daily Notification Settings',
              icon: Icon(
                _notificationsOn
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: _notificationsOn ? scheme.primary : null,
              ),
              onPressed: _openSettings,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _FilterRow(selected: _filter, onSelected: _setFilter),
                const SizedBox(height: 16),
                QuoteCard(quote: _quote),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: _bigButton,
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Quote'),
                        onPressed: _newQuote,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (buttonContext) => FilledButton.tonalIcon(
                          style: _bigButton,
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          onPressed: () => _share(buttonContext),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy to Clipboard'),
                    onPressed: _copy,
                  ),
                ),
                if (showNotificationUi && !_notificationsOn) ...[
                  const SizedBox(height: 20),
                  _HintBanner(onTurnOn: _openSettings),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _bigButton = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
  );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final ScriptureSource? selected;
  final ValueChanged<ScriptureSource?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, ScriptureSource? source) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(label,
                    textAlign: TextAlign.center, maxLines: 1, softWrap: false),
              ),
              showCheckmark: false,
              selected: selected == source,
              onSelected: (_) => onSelected(source),
            ),
          ),
        );

    return Row(
      children: [
        chip('All', null),
        for (final source in ScriptureSource.values)
          chip('${source.emoji} ${source.chipLabel}', source),
      ],
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '💡 Tap the bell icon to receive daily wisdom notifications',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onTurnOn, child: const Text('Turn On')),
        ],
      ),
    );
  }
}
