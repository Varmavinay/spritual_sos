import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reminder_sheet.dart';
import 'message_screen.dart';

/// Today's message, with Save and Share. Swipe the card for another one.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

/// Which message the home page shows: today's (the one the daily
/// notification brought, or the day's pick), or another the user moved on
/// to. Shared by the phone and desktop layouts.
mixin TodaysMessage<T extends StatefulWidget> on State<T> {
  ScriptureSource? filter;

  /// A quote the user moved on to; null shows today's message.
  Quote? browsed;

  /// Direction of the last change, so the card slides in from that side.
  int direction = 1;

  Quote todays() {
    final delivered = AppScope.of(context).library.todaysDelivery?.quote;
    if (delivered != null && (filter == null || delivered.source == filter)) {
      return delivered;
    }
    return dailyQuote(DateTime.now(), source: filter);
  }

  Quote get currentQuote => browsed ?? todays();

  String get currentLabel => browsed == null
      ? 'Today’s message'
      : 'From ${browsed!.source.withArticle}';

  void showAnother([int towards = 1]) {
    HapticFeedback.selectionClick();
    setState(() {
      direction = towards;
      browsed = randomQuote(source: filter, excluding: currentQuote);
    });
  }

  void setFilter(ScriptureSource? source) {
    if (source == filter) return;
    HapticFeedback.selectionClick();
    setState(() {
      filter = source;
      browsed = null;
    });
  }
}

class _HomeTabState extends State<HomeTab> with TodaysMessage {
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = SosColors.of(context);

    return ListenableBuilder(
      listenable: scope.library,
      builder: (context, _) {
        final quote = currentQuote;
        final saved = scope.library.isSaved(quote);
        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            SosHeader(
              title: 'Spiritual SOS',
              subtitle: 'Daily wisdom',
              leading: IconButton(
                tooltip: 'Menu',
                icon: Icon(Icons.menu_rounded, color: c.ink, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              trailing: IconButton(
                tooltip: 'Profile',
                onPressed: widget.onOpenProfile,
                icon: Avatar(name: scope.library.userName, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            SourceTabs(selected: filter, onSelected: setFilter),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SwipeableCard(
                quote: quote,
                label: currentLabel,
                direction: direction,
                onSwipe: showAnother,
                onTap: () => MessageScreen.open(context, quote),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: PillButton(
                      icon: Icon(saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded),
                      iconColor: c.accent,
                      label: saved ? 'Saved' : 'Save',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final now = scope.library.toggleSaved(quote);
                        showSnack(context,
                            now ? 'Saved to your history' : 'Removed from saved');
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Builder(
                      builder: (buttonContext) => PillButton(
                        icon: const Icon(Icons.ios_share_rounded),
                        label: 'Share',
                        onPressed: () => shareQuote(buttonContext, quote),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: showAnother,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Show another message'),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ReminderStrip(),
            ),
          ],
        );
      },
    );
  }
}

/// All / Bible / Gita / Quran tabs.
class SourceTabs extends StatelessWidget {
  const SourceTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.alignment = MainAxisAlignment.center,
  });

  final ScriptureSource? selected;
  final ValueChanged<ScriptureSource?> onSelected;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    Widget tab(String label, ScriptureSource? source) {
      final active = source == selected;
      return Semantics(
        selected: active,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelected(source),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? c.ink : c.muted,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 0,
                  height: 1.6,
                  color: c.accent,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      children: [
        tab('All', null),
        for (final source in ScriptureSource.values) tab(source.shortLabel, source),
      ],
    );
  }
}

class _SwipeableCard extends StatelessWidget {
  const _SwipeableCard({
    required this.quote,
    required this.label,
    required this.direction,
    required this.onSwipe,
    required this.onTap,
  });

  final Quote quote;
  final String label;
  final int direction;
  final ValueChanged<int> onSwipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 250) onSwipe(velocity < 0 ? -1 : 1);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(quote.id);
          final dx = 0.10 * (incoming ? -direction : direction);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: Offset(dx, 0), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: MessageCard(
          key: ValueKey(quote.id),
          quote: quote,
          label: label,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// The large message card from the home screen.
class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.quote,
    required this.label,
    this.onTap,
  });

  final Quote quote;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final length = quote.text.length;
    final size = length < 50
        ? 42.0
        : length < 90
            ? 35.0
            : length < 140
                ? 30.0
                : 26.0;

    return PaperCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(
            right: -4,
            bottom: -6,
            child: Opacity(opacity: 0.95, child: LeafSprig(width: 104, height: 150)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 22, 30),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: eyebrow(c.muted, fontSize: 10.5)),
                  const SizedBox(height: 12),
                  const AccentRule(width: 26),
                  const SizedBox(height: 22),
                  Text(
                    quote.text,
                    style: serif(fontSize: size, color: c.ink, height: 1.14),
                  ),
                  const SizedBox(height: 26),
                  const AccentRule(width: 30),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 96),
                    child: Text(
                      '${quote.citation}\n${quote.source.displayName}',
                      style: serif(fontSize: 18, color: c.muted, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily-message status; opens its settings.
class ReminderStrip extends StatelessWidget {
  const ReminderStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).notifications;
    final c = SosColors.of(context);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.availability == ReminderAvailability.unsupported) {
          return const SizedBox.shrink();
        }
        final on = service.enabled;
        return PaperCard(
          color: on ? c.card : c.blush,
          onTap: () => showReminderSheet(context),
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Icon(
                on ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: c.accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(on ? 'Daily message' : 'Get a daily message',
                        style: serif(fontSize: 19, color: c.ink)),
                    Text(
                      on
                          ? reminderSummary(context, service)
                          : 'Choose a time and a holy book',
                      style: TextStyle(fontSize: 13.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
        );
      },
    );
  }
}
