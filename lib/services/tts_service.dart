import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// TAVO — text-to-speech via ElevenLabs, using Salem's cloned voice.
/// Reverted to eleven_multilingual_v2 — eleven_turbo_v2_5 introduced loud
/// static/audio artifacts, not worth the latency gain.
class TtsService {
  static const _voiceId = 'vQdTBceFqJdj2D3Ug7Ow';
  static String get _endpoint =>
      'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId';

  Future<Uint8List> synthesize(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('ELEVENLABS_API_KEY missing — check .env');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.8,
          'use_speaker_boost': true,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('ElevenLabs TTS error ${response.statusCode}: ${response.body}');
    }

    return response.bodyBytes;
  }
}