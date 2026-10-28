import 'package:flutter/material.dart';

import '../models/quote.dart';

/// Pill-shaped tabs: All / Bible / Gita / Quran.
class ScriptureFilter extends StatelessWidget {
  const ScriptureFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ScriptureSource? selected;
  final ValueChanged<ScriptureSource?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget tab(String label, ScriptureSource? source) {
      final isSelected = selected == source;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => onSelected(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          tab('All', null),
          for (final source in ScriptureSource.values)
            tab('${source.emoji} ${source.chipLabel}', source),
        ],
      ),
    );
  }
}
