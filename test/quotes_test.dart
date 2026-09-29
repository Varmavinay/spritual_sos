import 'package:divine_quotes/data/quotes.dart';
import 'package:divine_quotes/models/quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has 20 quotes per scripture with unique ids', () {
    expect(allQuotes, hasLength(60));
    for (final source in ScriptureSource.values) {
      expect(quotesBySource(source), hasLength(20));
    }
    expect(allQuotes.map((q) => q.id).toSet(), hasLength(60));
  });

  test('randomQuote respects the filter and avoids repeats', () {
    for (var i = 0; i < 100; i++) {
      final previous = randomQuote(source: ScriptureSource.gita);
      final next =
          randomQuote(source: ScriptureSource.gita, excluding: previous);
      expect(next.source, ScriptureSource.gita);
      expect(next.id, isNot(previous.id));
    }
  });
}
