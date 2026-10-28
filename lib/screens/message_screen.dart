import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/quotes.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';

/// One message in full, with a place to write a reflection.
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key, required this.quote});

  final Quote quote;

  static Future<void> open(BuildContext context, Quote quote) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MessageScreen(quote: quote),
      ));

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late final _library = AppScope.of(context).library;
  late final _reflection =
      TextEditingController(text: _library.reflection(widget.quote));
  Timer? _saveTimer;

  void _onReflectionChanged(String text) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600),
        () => _library.setReflection(widget.quote, text));
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      // Save what was typed last, after this frame (listeners may rebuild).
      final quote = widget.quote;
      final text = _reflection.text;
      scheduleMicrotask(() => _library.setReflection(quote, text));
    }
    _reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final quote = widget.quote;
    final quoteSize = quote.text.length < 90
        ? 32.0
        : quote.text.length < 160
            ? 28.0
            : 25.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Message'),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => shareQuote(buttonContext, quote),
            ),
          ),
          ListenableBuilder(
            listenable: _library,
            builder: (context, _) {
              final saved = _library.isSaved(quote);
              return IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save',
                isSelected: saved,
                icon: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: c.accent,
                    size: 28),
                onPressed: () {
                  final now = _library.toggleSaved(quote);
                  showSnack(context, now ? 'Saved' : 'Removed from saved');
                },
              );
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: c.line, indent: 20, endIndent: 20),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 14),
                  // Opening marks: the closing "99" shape turned upside down.
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: CustomPaint(
                      size: const Size(30, 24),
                      painter: QuoteMarksPainter(c.accent),
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    quote.text,
                    style: serif(fontSize: quoteSize, color: c.ink, height: 1.28),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  const AccentRule(width: 34),
                  const SizedBox(height: 18),
                  Text(quote.citation,
                      style: TextStyle(fontSize: 16, color: c.ink, height: 1.4)),
                  const SizedBox(height: 2),
                  Text(quote.source.displayName,
                      style: TextStyle(fontSize: 15, color: c.muted)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PaperCard(
              color: c.blush,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco_rounded, color: c.accent, size: 24),
                      const SizedBox(width: 10),
                      Text('Reflection', style: serif(fontSize: 24, color: c.ink)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(reflectionPrompt(quote),
                      style: TextStyle(fontSize: 15.5, color: c.ink, height: 1.45)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _reflection,
                    onChanged: _onReflectionChanged,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts…',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Saved on this device only.',
                      style: TextStyle(fontSize: 12.5, color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
