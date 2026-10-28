import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reminder_sheet.dart';
import 'message_screen.dart';

enum HistoryView { received, saved }

/// Daily messages received on this device, and saved messages.
class HistoryTab extends StatefulWidget {
  const HistoryTab({
    super.key,
    this.view = HistoryView.received,
    this.onViewChanged,
  });

  final HistoryView view;
  final ValueChanged<HistoryView>? onViewChanged;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late HistoryView _view = widget.view;

  @override
  void didUpdateWidget(HistoryTab old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) _view = widget.view;
  }

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    final c = SosColors.of(context);
    final segments = _Segments(
      value: _view,
      onChanged: (v) {
        setState(() => _view = v);
        widget.onViewChanged?.call(v);
      },
    );
    final lists = Expanded(
      child: ListenableBuilder(
        listenable: library,
        builder: (context, _) => switch (_view) {
          HistoryView.received => _ReceivedList(),
          HistoryView.saved => _SavedList(),
        },
      ),
    );

    if (!isDesktop(context)) {
      return Column(
        children: [
          const SosHeader(title: 'History', subtitle: 'Your messages'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: segments,
          ),
          const SizedBox(height: 8),
          lists,
        ],
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopWidth + 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 48, 0, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR MESSAGES', style: eyebrow(c.muted, fontSize: 11.5)),
                          const SizedBox(height: 10),
                          Text('History', style: serif(fontSize: 44, color: c.ink, height: 1.1)),
                          const SizedBox(height: 14),
                          const AccentRule(width: 34),
                        ],
                      ),
                    ),
                    SizedBox(width: 380, child: segments),
                  ],
                ),
              ),
              lists,
            ],
          ),
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.value, required this.onChanged});

  final HistoryView value;
  final ValueChanged<HistoryView> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    Widget segment(HistoryView view, String label, IconData icon) {
      final active = view == value;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(view),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              decoration: BoxDecoration(
                color: active ? c.card : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                boxShadow: active
                    ? [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: active ? c.accent : c.muted),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? c.ink : c.muted,
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.blush,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          segment(HistoryView.received, 'Received', Icons.notifications_none_rounded),
          segment(HistoryView.saved, 'Saved', Icons.favorite_border_rounded),
        ],
      ),
    );
  }
}

class _ReceivedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final history = scope.library.history;
    if (history.isEmpty) {
      return ListenableBuilder(
        listenable: scope.notifications,
        builder: (context, _) {
          final on = scope.notifications.enabled;
          return _EmptyState(
            title: on ? 'Your first message is on its way' : 'No messages yet',
            body: on
                ? 'It arrives at ${scope.notifications.time.format(context)}. '
                    'Every daily message you receive will be kept here.'
                : 'Turn on the daily message and every one you receive will be kept here.',
            action: on
                ? null
                : FilledButton(
                    onPressed: () => showReminderSheet(context),
                    child: const Text('Set up daily message'),
                  ),
          );
        },
      );
    }
    return RefreshIndicator(
      color: SosColors.of(context).accent,
      onRefresh: scope.notifications.refreshHistory,
      child: _Tiles(
        count: history.length,
        builder: (context, i) => QuoteTile(
          quote: history[i].quote,
          caption: friendlyDateTime(context, history[i].at),
          icon: Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}

/// A list of tiles on phones; three columns on desktop.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.count, required this.builder});

  final int count;
  final IndexedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 48),
        children: [
          TileGrid(
            columns: 3,
            children: [for (var i = 0; i < count; i++) builder(context, i)],
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: builder,
    );
  }
}

/// Lays [children] out in rows of [columns].
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 20.0;
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: gap),
                  Expanded(
                    child: i < children.length ? children[i] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).library.saved;
    if (saved.isEmpty) {
      return const _EmptyState(
        title: 'Nothing saved yet',
        body: 'Tap Save on a message you love and it will wait for you here.',
      );
    }
    return _Tiles(
      count: saved.length,
      builder: (context, i) => QuoteTile(
        quote: saved[i],
        caption: saved[i].source.displayName,
        icon: Icons.favorite_rounded,
      ),
    );
  }
}

/// A message in a list; opens it in full when tapped.
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    required this.caption,
    required this.icon,
  });

  final Quote quote;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return PaperCard(
      onTap: () => MessageScreen.open(context, quote),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(caption.toUpperCase(),
                    style: eyebrow(c.muted, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quote.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: serif(fontSize: 20, color: c.ink, height: 1.25),
          ),
          const SizedBox(height: 8),
          Text('${quote.citation} · ${quote.source.displayName}',
              style: TextStyle(fontSize: 13, color: c.muted)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 48, 36, 28),
      children: [
        const Center(child: LeafSprig(width: 70, height: 100, leaves: 5)),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: serif(fontSize: 26, color: c.ink)),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: c.muted, height: 1.45)),
        if (action != null) ...[
          const SizedBox(height: 22),
          Center(child: action),
        ],
      ],
    );
  }
}
