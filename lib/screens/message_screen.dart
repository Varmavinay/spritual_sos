import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import '../widgets/reflection_box.dart';

/// One message in full, with a place to write a reflection. On desktop the
/// reflection sits beside the message.
class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key, required this.quote});

  final Quote quote;

  static Future<void> open(BuildContext context, Quote quote) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MessageScreen(quote: quote),
      ));

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final library = AppScope.of(context).library;
    final desktop = isDesktop(context);

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
            listenable: library,
            builder: (context, _) {
              final saved = library.isSaved(quote);
              return IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save',
                isSelected: saved,
                icon: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: c.accent,
                    size: 28),
                onPressed: () {
                  final now = library.toggleSaved(quote);
                  showSnack(context, now ? 'Saved' : 'Removed from saved');
                },
              );
            },
          ),
          SizedBox(width: desktop ? 24 : 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: c.line, indent: 20, endIndent: 20),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: desktop
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 56, 40, 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: desktopWidth),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _Message(quote: quote, large: true)),
                        const SizedBox(width: 64),
                        Expanded(flex: 4, child: ReflectionBox(quote: quote)),
                      ],
                    ),
                  ),
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                    24, 24, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _Message(quote: quote),
                  const SizedBox(height: 32),
                  ReflectionBox(quote: quote),
                ],
              ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.quote, this.large = false});

  final Quote quote;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final length = quote.text.length;
    final size = (length < 90 ? 32.0 : length < 160 ? 28.0 : 25.0) * (large ? 1.4 : 1);
    final indent = large ? 62.0 : 44.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: large ? 10 : 6, right: large ? 20 : 14),
              // Opening marks: the closing "99" shape turned upside down.
              child: RotatedBox(
                quarterTurns: 2,
                child: CustomPaint(
                  size: large ? const Size(42, 34) : const Size(30, 24),
                  painter: QuoteMarksPainter(c.accent),
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                quote.text,
                style: serif(fontSize: size, color: c.ink, height: 1.25),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              const AccentRule(width: 34),
              const SizedBox(height: 18),
              Text(quote.citation,
                  style: TextStyle(fontSize: large ? 18 : 16, color: c.ink, height: 1.4)),
              const SizedBox(height: 2),
              Text(quote.source.displayName,
                  style: TextStyle(fontSize: large ? 16 : 15, color: c.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
