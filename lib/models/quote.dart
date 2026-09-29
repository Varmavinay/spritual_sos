enum ScriptureSource {
  bible('Bible', '✝️'),
  gita('Bhagavad Gita', '🕉️'),
  quran('Quran', '☪️');

  const ScriptureSource(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  /// Short label used on the filter chips.
  String get chipLabel => switch (this) {
        ScriptureSource.bible => 'Bible',
        ScriptureSource.gita => 'Gita',
        ScriptureSource.quran => 'Quran',
      };
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
      '"$text"\n— $citation\n\n${source.emoji} ${source.displayName}';
}
