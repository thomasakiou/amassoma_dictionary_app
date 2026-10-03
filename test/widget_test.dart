import 'package:amassoma_dictionary/models/dictionary_entry.dart';
import 'package:amassoma_dictionary/services/dictionary_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a vocabulary table response', () {
    final entry = DictionaryEntry.fromJson({
      'id': 'sample-id',
      'word': 'Bo fiyai',
      'translation': 'Come eat',
      'pronunciation': 'Boh feeyai',
      'category': 'Sentence',
      'audio_url': '/amassoma/static/example.wav',
    });

    expect(entry.id, 'sample-id');
    expect(entry.word, 'Bo fiyai');
    expect(entry.translation, 'Come eat');
    expect(entry.pronunciation, 'Boh feeyai');
    expect(entry.category, 'Sentence');
    expect(entry.source, 'vocabulary');
    expect(entry.audioUrl, '/amassoma/static/example.wav');
  });

  test('maps a dictionary table response and trims phonetic HTML', () {
    final entry = DictionaryEntry.fromJson({
      'id': 'dictionary-id',
      'english_word': 'Man',
      'izon_word': 'Owei',
      'phonetic': '<b>oh-WAY</b><div>/o.we.i/</div><p>Explanation: details</p>',
      'audio_url': null,
    });

    expect(entry.word, 'Owei');
    expect(entry.translation, 'Man');
    expect(entry.category, 'Dictionary');
    expect(entry.source, 'dictionary');
    expect(entry.pronunciation, 'oh-WAY /o.we.i/');
  });

  test('resolves dictionary audio under the API mount prefix', () {
    const api = DictionaryApi();

    expect(
      api.audioUri('/static/uploads/audio.mp3').toString(),
      '$apiBaseUrl/static/uploads/audio.mp3',
    );
    expect(
      api.audioUri('/amassoma/static/uploads/audio.mp3').toString(),
      '$apiBaseUrl/static/uploads/audio.mp3',
    );
  });
}
