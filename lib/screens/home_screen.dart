import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quotes.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../widgets/quote_card.dart';
import '../widgets/reminder_card.dart';
import '../widgets/scripture_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.notifications});

  final NotificationService notifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScriptureSource? _filter;
  late Quote _quote = randomQuote();
  int _direction = 1;

  void _next([int direction = 1]) {
    HapticFeedback.selectionClick();
    setState(() {
      _direction = direction;
      _quote = randomQuote(source: _filter, excluding: _quote);
    });
  }

  void _setFilter(ScriptureSource? source) {
    if (source == _filter) return;
    setState(() => _filter = source);
    _next();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _quote.shareText));
    _showMessage('Quote copied to clipboard');
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                  scheme.primaryContainer.withValues(alpha: 0.55), scheme.surface),
              scheme.surface,
            ],
            stops: const [0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const _Header(),
                  const SizedBox(height: 20),
                  ScriptureFilter(selected: _filter, onSelected: _setFilter),
                  const SizedBox(height: 20),
                  QuoteCard(
                    quote: _quote,
                    swipeDirection: _direction,
                    onSwipe: _next,
                  ),
                  const SizedBox(height: 10),
                  _SwipeHint(color: scheme.onSurfaceVariant),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('New quote'),
                          onPressed: _next,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Builder(
                        builder: (buttonContext) => _SquareAction(
                          icon: Icons.ios_share,
                          tooltip: 'Share',
                          onPressed: () => _share(buttonContext),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SquareAction(
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy to clipboard',
                        onPressed: _copy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ReminderCard(
                    notifications: widget.notifications,
                    onMessage: _showMessage,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '60 verses · Bible · Bhagavad Gita · Quran',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

class _Header extends StatelessWidget {
  const _Header();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Peaceful night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sacred Wisdom',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/icon/icon.png',
              width: 48, height: 48, semanticLabel: 'Divine Quotes'),
        ),
      ],
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: color);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Swipe the card for another verse',
                style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size(56, 56),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
