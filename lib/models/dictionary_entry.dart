class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.word,
    required this.translation,
    required this.category,
    required this.source,
    this.pronunciation,
    this.audioUrl,
    this.authorUsername,
  });

  final String id;
  final String word;
  final String translation;
  final String category;
  final String source;
  final String? pronunciation;
  final String? audioUrl;
  final String? authorUsername;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final fromDictionary =
        json.containsKey('english_word') || json.containsKey('izon_word');
    final rawPronunciation = json['phonetic'] ?? json['pronunciation'];
    final pronunciation = rawPronunciation
        ?.toString()
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'\b(?:Explanation|Breakdown):', caseSensitive: false))
        .first
        .trim();
    return DictionaryEntry(
      id: json['id']?.toString() ?? '',
      word:
          (fromDictionary ? json['izon_word'] : json['word'])?.toString() ?? '',
      translation: (fromDictionary ? json['english_word'] : json['translation'])
              ?.toString() ??
          '',
      category: fromDictionary
          ? 'Dictionary'
          : json['category']?.toString() ?? 'Word',
      source: json['source']?.toString() ??
          (fromDictionary ? 'dictionary' : 'vocabulary'),
      pronunciation: (pronunciation?.isEmpty ?? true) ? null : pronunciation,
      audioUrl: json['audio_url']?.toString(),
      authorUsername: json['author_username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'translation': translation,
        'category': category,
        'source': source,
        'pronunciation': pronunciation,
        'audio_url': audioUrl,
        'author_username': authorUsername,
      };
}
