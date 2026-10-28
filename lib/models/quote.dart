enum ScriptureSource {
  bible('Bible', 'the Bible'),
  gita('Bhagavad Gita', 'the Bhagavad Gita'),
  quran('Quran', 'the Quran');

  const ScriptureSource(this.displayName, this.withArticle);

  final String displayName;

  /// For sentences such as "From the Bhagavad Gita".
  final String withArticle;

  /// Short label used on tabs.
  String get shortLabel => switch (this) {
        ScriptureSource.bible => 'Bible',
        ScriptureSource.gita => 'Gita',
        ScriptureSource.quran => 'Quran',
      };

  /// Parses [name]; anything else (including "all") means every scripture.
  static ScriptureSource? fromName(String? name) {
    for (final source in values) {
      if (source.name == name) return source;
    }
    return null;
  }
}

class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.source,
    required this.citation,
  });

  final int id;
  final String text;
  final ScriptureSource source;
  final String citation;

  /// Text used for sharing and copying to the clipboard.
  String get shareText =>
      '“$text”\n— $citation, ${source.displayName}\n\nShared from Spiritual SOS';
}
