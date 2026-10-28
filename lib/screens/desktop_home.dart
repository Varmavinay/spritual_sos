import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reflection_box.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'message_screen.dart';

/// The home page of the desktop website: today's message set large, the
/// reflection and daily-message panels, the three books, and recent
/// messages.
class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key, required this.onOpenHistory});

  final void Function(HistoryView view) onOpenHistory;

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> with TodaysMessage {
  final _scroll = ScrollController();

  void _readMore(ScriptureSource source) {
    setFilter(source);
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final quote = currentQuote;
        return SingleChildScrollView(
          controller: _scroll,
          child: Column(
            children: [
              DesktopSection(
                padding: const EdgeInsets.fromLTRB(40, 56, 40, 64),
                child: _Hero(
                  quote: quote,
                  label: currentLabel,
                  filter: filter,
                  onFilter: setFilter,
                  onAnother: showAnother,
                ),
              ),
              DesktopSection(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 72),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ReflectionBox(
                          key: ValueKey(quote.id),
                          quote: quote,
                          title: 'Reflect on this message',
                        ),
                      ),
                      const SizedBox(width: 28),
                      const Expanded(flex: 2, child: _DailyMessagePanel()),
                    ],
                  ),
                ),
              ),
              DesktopSection(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 72),
                child: _Books(onReadMore: _readMore),
              ),
              if (library.history.isNotEmpty || library.saved.isNotEmpty)
                DesktopSection(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 72),
                  child: _Recent(onOpenHistory: widget.onOpenHistory),
                ),
              const DesktopFooter(),
            ],
          ),
        );
      },
    );
  }
}

/// Centres a band of the desktop page at [desktopWidth].
class DesktopSection extends StatelessWidget {
  const DesktopSection({super.key, required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: desktopWidth),
            child: child,
          ),
        ),
      );
}

/// Section title: spaced kicker, serif heading and a short rule.
class DesktopHeading extends StatelessWidget {
  const DesktopHeading({super.key, required this.kicker, required this.title, this.trailing});

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker.toUpperCase(), style: eyebrow(c.muted, fontSize: 11.5)),
                const SizedBox(height: 10),
                Text(title, style: serif(fontSize: 38, color: c.ink, height: 1.1)),
                const SizedBox(height: 14),
                const AccentRule(width: 34),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.quote,
    required this.label,
    required this.filter,
    required this.onFilter,
    required this.onAnother,
  });

  final Quote quote;
  final String label;
  final ScriptureSource? filter;
  final ValueChanged<ScriptureSource?> onFilter;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final library = AppScope.of(context).library;
    final saved = library.isSaved(quote);
    final length = quote.text.length;
    final size = length < 60 ? 60.0 : length < 110 ? 50.0 : length < 160 ? 42.0 : 36.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Column(
              key: ValueKey(quote.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SourceTabs(
                  selected: filter,
                  onSelected: onFilter,
                  alignment: MainAxisAlignment.start,
                ),
                const SizedBox(height: 34),
                Text(label.toUpperCase(), style: eyebrow(c.muted, fontSize: 12)),
                const SizedBox(height: 14),
                const AccentRule(width: 34),
                const SizedBox(height: 28),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => MessageScreen.open(context, quote),
                    child: Text(quote.text,
                        style: serif(fontSize: size, color: c.ink, height: 1.12)),
                  ),
                ),
                const SizedBox(height: 30),
                const AccentRule(width: 34),
                const SizedBox(height: 18),
                Text('${quote.citation}  ·  ${quote.source.displayName}',
                    style: serif(fontSize: 21, color: c.muted)),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    PillButton(
                      icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      iconColor: c.accent,
                      label: saved ? 'Saved' : 'Save',
                      onPressed: () {
                        final now = library.toggleSaved(quote);
                        showSnack(context, now ? 'Saved to your history' : 'Removed from saved');
                      },
                    ),
                    Builder(
                      builder: (buttonContext) => PillButton(
                        icon: const Icon(Icons.ios_share_rounded),
                        label: 'Share',
                        onPressed: () => shareQuote(buttonContext, quote),
                      ),
                    ),
                    PillButton(
                      icon: const Icon(Icons.refresh_rounded),
                      iconColor: c.accent,
                      label: 'Another message',
                      onPressed: onAnother,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 56),
        const Expanded(flex: 4, child: _HeroArt()),
      ],
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return AspectRatio(
      aspectRatio: 0.82,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: ColoredBox(
          color: c.card,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final hills = box.maxHeight * 0.32;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: hills,
                    child: CustomPaint(
                      painter: HillsPainter(
                        colors: [c.blush, c.sand, Color.lerp(c.accent, c.sand, 0.25)!],
                        line: c.card.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Positioned(
                    right: w * 0.06,
                    bottom: hills * 0.25,
                    child: LeafSprig(
                        width: w * 0.24, height: w * 0.37, paleTip: false, flip: true),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: box.maxHeight * 0.12,
                    child: Column(
                      children: [
                        Emblem(size: w * 0.52),
                        SizedBox(height: w * 0.05),
                        Text('Small words.\nA little more light.',
                            textAlign: TextAlign.center,
                            style: serif(fontSize: w * 0.052, color: c.muted, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DailyMessagePanel extends StatelessWidget {
  const _DailyMessagePanel();

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return PaperCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_none_rounded, color: c.accent, size: 30),
          const SizedBox(height: 14),
          Text('A message every day', style: serif(fontSize: 28, color: c.ink)),
          const SizedBox(height: 8),
          Text(
            'Choose a time and a holy book (the Bible, the Bhagavad Gita, the '
            'Quran, or all three), and a few words will arrive each day, even '
            'when this site is closed.',
            style: TextStyle(fontSize: 15, color: c.muted, height: 1.5),
          ),
          const Spacer(),
          const SizedBox(height: 22),
          const ReminderStrip(),
        ],
      ),
    );
  }
}

class _Books extends StatelessWidget {
  const _Books({required this.onReadMore});

  final ValueChanged<ScriptureSource> onReadMore;

  static const _blurbs = {
    ScriptureSource.bible: 'Psalms, Proverbs, the Gospels and the letters: words of hope, courage and rest.',
    ScriptureSource.gita: 'Krishna’s counsel to Arjuna on duty, the steady mind and letting go of results.',
    ScriptureSource.quran: 'Verses of mercy, patience and trust, and the promise that ease follows hardship.',
  };

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DesktopHeading(kicker: 'Three holy books', title: 'Wisdom from every tradition'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final source in ScriptureSource.values) ...[
                if (source != ScriptureSource.values.first) const SizedBox(width: 24),
                Expanded(
                  child: PaperCard(
                    padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('The ${source.displayName}', style: serif(fontSize: 28, color: c.ink)),
                        const SizedBox(height: 8),
                        Text(_blurbs[source]!,
                            style: TextStyle(fontSize: 14.5, color: c.muted, height: 1.5)),
                        const SizedBox(height: 20),
                        const AccentRule(width: 26),
                        const SizedBox(height: 16),
                        Text('“${dailyQuote(today, source: source).text}”',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: serif(fontSize: 19, color: c.ink, height: 1.35)),
                        const Spacer(),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => onReadMore(source),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text('Read from the ${source.shortLabel}'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.onOpenHistory});

  final void Function(HistoryView view) onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    final received = library.history.isNotEmpty;
    final tiles = received
        ? [
            for (final d in library.history.take(3))
              QuoteTile(
                quote: d.quote,
                caption: friendlyDateTime(context, d.at),
                icon: Icons.notifications_none_rounded,
              ),
          ]
        : [
            for (final q in library.saved.take(3))
              QuoteTile(quote: q, caption: q.source.displayName, icon: Icons.favorite_rounded),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopHeading(
          kicker: received ? 'Your history' : 'Saved',
          title: received ? 'Recent messages' : 'Messages you saved',
          trailing: TextButton.icon(
            onPressed: () => onOpenHistory(received ? HistoryView.received : HistoryView.saved),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('See all'),
          ),
        ),
        TileGrid(columns: 3, children: tiles),
      ],
    );
  }
}

/// The site footer: name, tagline and the hills.
class DesktopFooter extends StatelessWidget {
  const DesktopFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned.fill(
            top: 60,
            child: CustomPaint(
              painter: HillsPainter(
                colors: [c.blush, c.sand, Color.lerp(c.accent, c.sand, 0.25)!],
                line: c.card.withValues(alpha: 0.7),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Text('Spiritual SOS', style: serif(fontSize: 30, color: c.ink)),
                const SizedBox(height: 6),
                Text('Small words. A little more light.',
                    style: serif(fontSize: 17, color: c.muted)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Text(
              '60 messages from the Bible, the Bhagavad Gita and the Quran · '
              'Your name, saved messages and reflections stay on this device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: c.card),
            ),
          ),
        ],
      ),
    );
  }
}
