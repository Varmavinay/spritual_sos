import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../models/quote.dart';
import '../theme.dart';
import 'common.dart';

/// A journaling prompt for [quote] and a note that saves as you type
/// (on this device only).
class ReflectionBox extends StatefulWidget {
  const ReflectionBox({super.key, required this.quote, this.title = 'Reflection'});

  final Quote quote;
  final String title;

  @override
  State<ReflectionBox> createState() => _ReflectionBoxState();
}

class _ReflectionBoxState extends State<ReflectionBox> {
  late final _library = AppScope.of(context).library;
  late final _controller =
      TextEditingController(text: _library.reflection(widget.quote));
  Timer? _saveTimer;

  @override
  void didUpdateWidget(ReflectionBox old) {
    super.didUpdateWidget(old);
    if (old.quote.id != widget.quote.id) {
      _flush(old.quote);
      _controller.text = _library.reflection(widget.quote);
    }
  }

  void _onChanged(String text) {
    _saveTimer?.cancel();
    final quote = widget.quote;
    _saveTimer = Timer(const Duration(milliseconds: 600),
        () => _library.setReflection(quote, text));
  }

  /// Saves what was typed last for [quote], after this frame (listeners may
  /// rebuild).
  void _flush(Quote quote) {
    if (!(_saveTimer?.isActive ?? false)) return;
    _saveTimer!.cancel();
    final text = _controller.text;
    scheduleMicrotask(() => _library.setReflection(quote, text));
  }

  @override
  void dispose() {
    _flush(widget.quote);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return PaperCard(
      color: c.blush,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: c.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title, style: serif(fontSize: 24, color: c.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reflectionPrompt(widget.quote),
              style: TextStyle(fontSize: 15.5, color: c.ink, height: 1.45)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Write your thoughts…'),
          ),
          const SizedBox(height: 8),
          Text('Saved on this device only.',
              style: TextStyle(fontSize: 12.5, color: c.muted)),
        ],
      ),
    );
  }
}
