// Writes the quotes used by the push server (push-server/src/quotes.json)
// from lib/data/quotes.dart, so both share one list.
//
// Run after editing quotes:  dart run tool/export_quotes.dart
import 'dart:convert';
import 'dart:io';

import 'package:divine_quotes/data/quotes.dart';

void main() {
  final json = const JsonEncoder.withIndent('  ').convert([
    for (final q in allQuotes)
      {
        'id': q.id,
        'text': q.text,
        'citation': q.citation,
        'book': q.source.name,
        'source': q.source.displayName,
        'from': q.source.withArticle,
      },
  ]);
  File('push-server/src/quotes.json').writeAsStringSync('$json\n');
  stdout.writeln('Wrote ${allQuotes.length} quotes to push-server/src/quotes.json');
}
