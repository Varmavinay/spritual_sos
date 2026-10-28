import 'package:divine_quotes/data/quotes.dart';
import 'package:divine_quotes/services/library_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LibraryStore> _load() async {
  SharedPreferences.setMockInitialValues({});
  return LibraryStore(await SharedPreferences.getInstance());
}

void main() {
  test('saved quotes, reflections and name survive a restart', () async {
    final store = await _load();
    store.toggleSaved(quoteById(3)!);
    store.toggleSaved(quoteById(30)!);
    store.toggleSaved(quoteById(3)!); // Un-save.
    store.setReflection(quoteById(30)!, 'Stay steady.');
    store.setUserName(' Asha ');

    final reloaded = LibraryStore(await SharedPreferences.getInstance());
    expect(reloaded.saved.map((q) => q.id), [30]);
    expect(reloaded.reflection(quoteById(30)!), 'Stay steady.');
    expect(reloaded.userName, 'Asha');
  });

  test('history is newest first, without duplicates', () async {
    final store = await _load();
    final now = DateTime.now();
    final older = Delivery(quoteById(1)!, now.subtract(const Duration(days: 2)));
    final newer = Delivery(quoteById(2)!, now.subtract(const Duration(seconds: 1)));
    store.addDeliveries([older]);
    store.addDeliveries([newer, older]);

    expect(store.history, [newer, older]);
    final reloaded = LibraryStore(await SharedPreferences.getInstance());
    expect(reloaded.history, [newer, older]);
  });

  test('daily quote is stable within a day and changes the next day', () {
    final day = DateTime(2026, 10, 28, 9);
    expect(dailyQuote(day).id, dailyQuote(DateTime(2026, 10, 28, 23)).id);
    expect(dailyQuote(day).id, isNot(dailyQuote(DateTime(2026, 10, 29)).id));
  });
}
