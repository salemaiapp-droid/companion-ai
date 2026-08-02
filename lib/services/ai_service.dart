import 'ai/ai_provider.dart';
import 'ai/openai_provider.dart';
import 'ai/prompt_builder.dart';

/// TAVO — AI conversation service.
///
/// Phase 1 of the architecture refactor: no longer talks to OpenAI
/// directly (see lib/services/ai/*), no longer holds one giant prompt
/// string (see PromptBuilder). Public API unchanged — nothing else in
/// the app needed to change.
class AiService {
  // Swap providers here — zero other code changes needed anywhere.
  static final AiProvider _provider = OpenAiProvider();

  Future<String> openConversation({required String timeGreeting}) {
    final systemPrompt = PromptBuilder.build();
    return _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content':
            '[بداية الجلسة — افتتح حديثك بتحية "$timeGreeting" بالضبط، ثم انتقل مباشرة لموضوع أو قصة أو رأي من الواقع العربي أو الخليجي، بدون إنهاء كلامك بسؤال إطلاقاً]',
      },
    ]);
  }

  Future<String> reply(
    String userMessage, {
    required List<Map<String, String>> history,
    bool wasInterruption = false,
    bool allowQuestion = false,
  }) {
    final systemPrompt = PromptBuilder.build();
    final tag = wasInterruption ? '[مقاطعة] ' : '';
    final permission = allowQuestion ? '' : ' [لا تنهِ ردّك بسؤال هالمرة]';
    return _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': '$tag$userMessage$permission'},
    ]);
  }

  Future<String> continueTalking({required List<Map<String, String>> history}) {
    final systemPrompt = PromptBuilder.build();
    return _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {
        'role': 'user',
        'content':
            '[استمرار طبيعي — اربط بجسر منطقي بين اللي قلته وبين فكرة أو قصة جديدة من الواقع العربي/الخليجي، بلا قفزة مفاجئة. ممنوع إنهاء الرد بسؤال]',
      },
    ]);
  }
}