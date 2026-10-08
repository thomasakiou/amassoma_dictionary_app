import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tutor_message.dart';
import 'dictionary_api.dart';

class TutorApi {
  const TutorApi({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<TutorReply> ask({
    required String question,
    required String mode,
    required List<TutorMessage> conversation,
    required List<String> contextEntryIds,
  }) async {
    final client = _client ?? http.Client();
    final recentConversation = conversation.length > 12
        ? conversation.sublist(conversation.length - 12)
        : conversation;
    try {
      final response = await client
          .post(
            Uri.parse('$apiBaseUrl/api/learning/tutor'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              'mode': mode,
              'conversation':
                  recentConversation.map((turn) => turn.toTurnJson()).toList(),
              'context_entry_ids': contextEntryIds,
            }),
          )
          .timeout(const Duration(seconds: 45));

      dynamic payload;
      try {
        payload = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw Exception('The tutor returned an unreadable response.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload is Map<String, dynamic>
            ? payload['detail']?.toString() ?? payload['error']?.toString()
            : null;
        throw Exception(message ?? 'The tutor service is unavailable.');
      }
      if (payload is! Map<String, dynamic>) {
        throw const FormatException(
            'The tutor response has an unexpected format.');
      }
      return TutorReply.fromJson(payload);
    } finally {
      if (_client == null) client.close();
    }
  }
}
