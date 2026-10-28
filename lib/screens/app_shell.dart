import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reminder_sheet.dart';
import 'desktop_home.dart';
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
    final history = HistoryTab(
      view: _historyView,
      onViewChanged: (view) => setState(() => _historyView = view),
    );
    final profile = ProfileTab(
      onOpenSaved: () => _select(1, view: HistoryView.saved),
      onOpenReceived: () => _select(1, view: HistoryView.received),
    );

    if (isDesktop(context)) {
      return Scaffold(
        body: Column(
          children: [
            _TopBar(
              tab: _tab,
              historyView: _historyView,
              onSelect: _select,
              onReminder: () => showReminderSheet(context),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  DesktopHome(onOpenHistory: (view) => _select(1, view: view)),
                  history,
                  profile,
                ],
              ),
            ),
          ],
        ),
      );
    }

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
            history,
            profile,
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(index: _tab, onSelect: _select),
    );
  }
}

/// Navigation bar across the top of the desktop website.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tab,
    required this.historyView,
    required this.onSelect,
    required this.onReminder,
  });

  final int tab;
  final HistoryView historyView;
  final void Function(int tab, {HistoryView? view}) onSelect;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = SosColors.of(context);

    Widget link(String label, bool active, VoidCallback onTap) => Semantics(
          selected: active,
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? c.ink : c.muted,
                      )),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 20 : 0,
                    height: 1.6,
                    color: c.accent,
                  ),
                ],
              ),
            ),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopWidth),
              child: SizedBox(
                height: 80,
                child: ListenableBuilder(
                  listenable: Listenable.merge([scope.library, scope.notifications]),
                  builder: (context, _) => Row(
                    children: [
                      InkWell(
                        onTap: () => onSelect(0),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CustomPaint(
                                size: const Size(30, 24),
                                painter: QuoteMarksPainter(c.accent),
                              ),
                              const SizedBox(width: 12),
                              Text('Spiritual SOS',
                                  style: serif(fontSize: 28, color: c.ink, height: 1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Shrinks rather than overflowing on narrow windows.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                link('Today', tab == 0, () => onSelect(0)),
                                link('History',
                                    tab == 1 && historyView == HistoryView.received,
                                    () => onSelect(1, view: HistoryView.received)),
                                link('Saved', tab == 1 && historyView == HistoryView.saved,
                                    () => onSelect(1, view: HistoryView.saved)),
                                link('Profile', tab == 2, () => onSelect(2)),
                                const SizedBox(width: 20),
                                if (scope.notifications.availability !=
                                    ReminderAvailability.unsupported)
                                  scope.notifications.enabled
                                      ? OutlinedButton.icon(
                                          onPressed: onReminder,
                                          icon: Icon(Icons.notifications_active_rounded,
                                              color: c.accent, size: 20),
                                          label: Text(
                                              'Daily · ${scope.notifications.time.format(context)}'),
                                          style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 46)),
                                        )
                                      : FilledButton.icon(
                                          onPressed: onReminder,
                                          icon: const Icon(Icons.notifications_none_rounded,
                                              size: 20),
                                          label: const Text('Daily message'),
                                          style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 46)),
                                        ),
                                const SizedBox(width: 16),
                                IconButton(
                                  tooltip: 'Profile',
                                  onPressed: () => onSelect(2),
                                  icon: Avatar(name: scope.library.userName, size: 42),
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
            ),
          ),
        ),
      ),
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
