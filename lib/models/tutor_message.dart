class TutorMessage {
  const TutorMessage({
    required this.role,
    required this.content,
    this.sources = const [],
    this.followUpQuestions = const [],
  });

  final String role;
  final String content;
  final List<TutorSource> sources;
  final List<String> followUpQuestions;

  Map<String, String> toTurnJson() => {'role': role, 'content': content};
}

class TutorSource {
  const TutorSource({
    required this.entryId,
    required this.word,
    required this.translation,
    this.category = '',
    this.source = 'vocabulary',
    this.pronunciation,
    this.audioUrl,
  });

  final String entryId;
  final String word;
  final String translation;
  final String category;
  final String source;
  final String? pronunciation;
  final String? audioUrl;

  factory TutorSource.fromJson(Map<String, dynamic> json) => TutorSource(
        entryId: json['entry_id']?.toString() ?? '',
        word: json['word']?.toString() ?? '',
        translation: json['translation']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        source: json['source']?.toString() ?? 'vocabulary',
        pronunciation: json['pronunciation']?.toString(),
        audioUrl: json['audio_url']?.toString(),
      );
}

class TutorReply {
  const TutorReply({
    required this.answer,
    this.sources = const [],
    this.followUpQuestions = const [],
  });

  final String answer;
  final List<TutorSource> sources;
  final List<String> followUpQuestions;

  factory TutorReply.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const FormatException('The tutor response has no answer.');
    }

    final rawSources = json['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map>()
            .map((source) =>
                TutorSource.fromJson(Map<String, dynamic>.from(source)))
            .toList(growable: false)
        : const <TutorSource>[];
    final rawFollowUps = json['follow_up_questions'];
    final followUpQuestions = rawFollowUps is List
        ? rawFollowUps
            .whereType<String>()
            .map((question) => question.trim())
            .where((question) => question.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return TutorReply(
      answer: answer.trim(),
      sources: sources,
      followUpQuestions: followUpQuestions,
    );
  }
}
