import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/reminder_sheet.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'message_screen.dart';
import 'profile_tab.dart';

/// The three tabs (Home, History, Profile) and the side menu.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _tab = 0;
  HistoryView _historyView = HistoryView.received;
  late final _notifications = AppScope.of(context).notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifications.openRequest.removeListener(_openRequested);
    _notifications.openRequest.addListener(_openRequested);
    // A reminder may have been tapped before this screen existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequested());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.openRequest.removeListener(_openRequested);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up reminders that arrived while the app was in the background.
    if (state == AppLifecycleState.resumed) _notifications.refreshHistory();
  }

  void _openRequested() {
    final id = _notifications.openRequest.value;
    if (id == null || !mounted) return;
    _notifications.openRequest.value = null;
    final quote = quoteById(id);
    if (quote == null) return;
    _notifications.refreshHistory();
    Navigator.of(context).popUntil((route) => route.isFirst);
    MessageScreen.open(context, quote);
  }

  void _select(int tab, {HistoryView? view}) {
    setState(() {
      _tab = tab;
      if (view != null) _historyView = view;
    });
    if (tab == 1) _notifications.refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _Menu(
        onSelect: _select,
        onReminder: () => showReminderSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeTab(onOpenProfile: () => _select(2)),
            HistoryTab(view: _historyView),
            ProfileTab(
              onOpenSaved: () => _select(1, view: HistoryView.saved),
              onOpenReceived: () => _select(1, view: HistoryView.received),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(index: _tab, onSelect: _select),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.history_rounded, Icons.history_rounded, 'History'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: items[i].$3,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onSelect(i),
                      radius: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(i == index ? items[i].$2 : items[i].$1,
                              size: 27, color: i == index ? c.accent : c.muted),
                          const SizedBox(height: 3),
                          Text(
                            items[i].$3,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                              color: i == index ? c.accent : c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.onSelect, required this.onReminder});

  final void Function(int tab, {HistoryView? view}) onSelect;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = SosColors.of(context);
    final name = scope.library.userName;

    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: c.accent),
          title: Text(label, style: TextStyle(fontSize: 16, color: c.ink)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(name: name, size: 56),
                  const SizedBox(height: 14),
                  Text(name.isEmpty ? 'Peace be with you' : 'Peace be with you,\n$name',
                      style: serif(fontSize: 24, color: c.ink, height: 1.2)),
                  const SizedBox(height: 12),
                  const AccentRule(),
                ],
              ),
            ),
            item(Icons.home_outlined, 'Today', () => onSelect(0)),
            item(Icons.history_rounded, 'History',
                () => onSelect(1, view: HistoryView.received)),
            item(Icons.favorite_border_rounded, 'Saved messages',
                () => onSelect(1, view: HistoryView.saved)),
            item(Icons.notifications_none_rounded, 'Daily message',
                onReminder),
            item(Icons.person_outline_rounded, 'Profile', () => onSelect(2)),
          ],
        ),
      ),
    );
  }
}
