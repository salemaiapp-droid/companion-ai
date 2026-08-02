import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai_provider.dart';

/// OpenAI GPT-4o implementation of [AiProvider].
class OpenAiProvider implements AiProvider {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o';

  @override
  Future<String> complete(
    List<Map<String, String>> messages, {
    double temperature = 0.9,
    double presencePenalty = 0.9,
    double frequencyPenalty = 0.4,
    int maxTokens = 400,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('OPENAI_API_KEY missing — check .env');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'presence_penalty': presencePenalty,
        'frequency_penalty': frequencyPenalty,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return (data['choices'][0]['message']['content'] as String).trim();
  }
}