import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quote.dart';

/// The main quote card. Swipe it sideways for another quote.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onSwipe,
    this.swipeDirection = 1,
  });

  final Quote quote;

  /// Called with -1 (swiped left) or 1 (swiped right).
  final ValueChanged<int> onSwipe;

  /// Direction of the last change, so the new card slides in from that side.
  final int swipeDirection;

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
          final dx = 0.12 * (incoming ? -swipeDirection : swipeDirection);
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
        child: _CardBody(key: ValueKey(quote.id), quote: quote),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Large decorative quotation mark.
          Positioned(
            top: -18,
            left: 14,
            child: ExcludeSemantics(
              child: Text(
                '“',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 150,
                  height: 1,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            child: Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.65),
                    ),
                    child: ExcludeSemantics(
                      child: Text(quote.source.emoji,
                          style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quote.source.displayName.toUpperCase(),
                    style: text.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    quote.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 21,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      quote.citation,
                      style: text.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
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
