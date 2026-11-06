import 'quote.dart';

/// The religion the user chose on first launch. It picks the holy book the
/// app shows and sends by default.
enum Faith {
  christian('Christian', ScriptureSource.bible),
  hindu('Hindu', ScriptureSource.gita),
  muslim('Muslim', ScriptureSource.quran),
  sikh('Sikh', ScriptureSource.granth),
  none('No particular religion', null);

  const Faith(this.label, this.book);

  final String label;

  /// The holy book for this faith; null means all of them.
  final ScriptureSource? book;

  /// Shown under the label when choosing.
  String get description => book == null
      ? 'Wisdom from all four holy books'
      : 'Messages from ${book!.withArticle}';

  static Faith? fromName(String? name) {
    for (final faith in values) {
      if (faith.name == name) return faith;
    }
    return null;
  }
}
