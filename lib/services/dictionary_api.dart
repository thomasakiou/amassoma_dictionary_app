import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dictionary_entry.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://vmi2848672.contaboserver.net/amassoma',
);

class DictionaryApi {
  const DictionaryApi();

  Future<List<DictionaryEntry>> fetchEntries() async {
    final results = await Future.wait([
      _fetchWords('/dictionary?skip=0&limit=100', 'words'),
      _fetchWords('/api/learning/vocabulary?skip=0&limit=100', 'items'),
    ]);
    return results.expand((entries) => entries).toList(growable: false);
  }

  Future<List<DictionaryEntry>> _fetchWords(String path, String listKey) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          'The dictionary service returned ${response.statusCode}.');
    }

    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map<String, dynamic> || payload[listKey] is! List) {
      throw const FormatException(
          'The dictionary response has an unexpected format.');
    }

    return (payload[listKey] as List)
        .whereType<Map<String, dynamic>>()
        .map(DictionaryEntry.fromJson)
        .where((entry) => entry.id.isNotEmpty && entry.word.isNotEmpty)
        .toList(growable: false);
  }

  Uri audioUri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final base = Uri.parse(apiBaseUrl);
    final basePath = base.path.replaceFirst(RegExp(r'/$'), '');
    final assetPath = path.startsWith('/') ? path : '/$path';
    final alreadyPrefixed =
        basePath.isEmpty || assetPath.startsWith('$basePath/');
    if (basePath.isNotEmpty && !alreadyPrefixed) {
      return base.resolve('$basePath$assetPath');
    }
    return base.resolve(assetPath);
  }
}
