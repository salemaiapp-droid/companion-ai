import 'ai/ai_provider.dart';
import 'ai/openai_provider.dart';
import 'ai/conversation_brain.dart';
import 'ai/conversation_director.dart';
import 'ai/personality_engine.dart';

class AiService {
  static final AiProvider _provider = OpenAiProvider();
  final PersonalityEngine _personality = PersonalityEngine();
  final ConversationBrain _brain = ConversationBrain();
  late final ConversationDirector _director = ConversationDirector(_personality);

  Future<String> openConversation({required String timeGreeting}) async {
    final signal = _brain.onOpen();
    final systemPrompt = _director.buildSystemPrompt();
    final userMessage = _director.buildOpeningMessage(signal, timeGreeting: timeGreeting);

    final reply = await _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ]);
    _brain.recordAssistantReply(reply);
    return reply;
  }

  Future<String> reply(String userMessage, {required List<Map<String, String>> history, bool wasInterruption = false}) async {
    _personality.detectSwitch(userMessage);

    final signal = _brain.onUserReply(userMessage, wasInterruption: wasInterruption);
    final systemPrompt = _director.buildSystemPrompt();
    final content = _director.buildReplyMessage(signal, userMessage: userMessage, wasInterruption: wasInterruption);

    final reply = await _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': content},
    ]);
    _brain.recordAssistantReply(reply);
    return reply;
  }

  Future<String> continueTalking({required List<Map<String, String>> history}) async {
    final signal = _brain.onSilence();
    final systemPrompt = _director.buildSystemPrompt();
    final content = _director.buildContinueMessage(signal);

    final reply = await _provider.complete([
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': content},
    ]);
    _brain.recordAssistantReply(reply);
    return reply;
  }
}
