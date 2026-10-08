import 'dart:convert';

import 'package:amassoma_dictionary/models/tutor_message.dart';
import 'package:amassoma_dictionary/services/tutor_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends tutor context and maps grounded answer sources', () async {
    late http.Request capturedRequest;
    final api = TutorApi(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'answer': 'Start with this greeting.',
            'sources': [
              {
                'entry_id': 'greeting-1',
                'word': 'Sample greeting',
                'translation': 'Hello',
                'category': 'Greeting',
                'source': 'vocabulary',
                'pronunciation': 'sample pronunciation',
                'audio_url': '/audio/greeting.mp3',
              }
            ],
            'follow_up_questions': ['Quiz me on greetings'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final reply = await api.ask(
      question: 'How do I greet someone?',
      mode: 'ask',
      conversation: const [
        TutorMessage(role: 'user', content: 'Teach me a greeting'),
      ],
      contextEntryIds: const ['saved-1', 'recent-1'],
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, endsWith('/api/learning/tutor'));
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['question'], 'How do I greet someone?');
    expect(body['mode'], 'ask');
    expect(body['context_entry_ids'], ['saved-1', 'recent-1']);
    expect(body['conversation'], [
      {'role': 'user', 'content': 'Teach me a greeting'},
    ]);
    expect(reply.answer, 'Start with this greeting.');
    expect(reply.sources.single.entryId, 'greeting-1');
    expect(reply.sources.single.pronunciation, 'sample pronunciation');
    expect(reply.sources.single.audioUrl, '/audio/greeting.mp3');
    expect(reply.followUpQuestions, ['Quiz me on greetings']);
  });

  test('limits the transmitted history to the latest 12 messages', () async {
    late http.Request capturedRequest;
    final api = TutorApi(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'answer': 'Next step.'}), 200);
      }),
    );

    final conversation = List.generate(
      15,
      (index) => TutorMessage(
        role: index.isEven ? 'user' : 'assistant',
        content: 'turn-$index',
      ),
    );
    await api.ask(
      question: 'Continue',
      mode: 'practice',
      conversation: conversation,
      contextEntryIds: const [],
    );

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    final turns = body['conversation'] as List;
    expect(turns, hasLength(12));
    expect(turns.first['content'], 'turn-3');
    expect(turns.last['content'], 'turn-14');
  });
}
