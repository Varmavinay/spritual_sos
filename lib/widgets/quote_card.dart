import 'package:flutter/material.dart';

import '../models/quote.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(quote.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Semantics(
          liveRegion: true,
          child: Column(
            children: [
              ExcludeSemantics(
                child: Text(quote.source.emoji,
                    style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 8),
              Text(
                quote.source.displayName.toUpperCase(),
                style: text.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '“${quote.text}”',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  fontSize: 19,
                  height: 1.65,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '— ${quote.citation}',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
