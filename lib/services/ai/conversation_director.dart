import 'conversation_brain.dart';
import 'personality_engine.dart';
import 'prompt_builder.dart';

class ConversationDirector {
  ConversationDirector(this._personality);

  final PersonalityEngine _personality;

  String buildSystemPrompt() {
    return PromptBuilder.build(personaFragment: _personality.activePromptFragment);
  }

  String buildOpeningMessage(ConversationSignal signal, {required String timeGreeting}) {
    return '[بداية الجلسة — افتتح حديثك بتحية "$timeGreeting" بالضبط، ثم انتقل مباشرة لموضوع من فئة "${signal.topicCategory}" من الواقع العربي أو الخليجي، بدون إنهاء كلامك بسؤال إطلاقاً]';
  }

  String buildReplyMessage(ConversationSignal signal, {required String userMessage, required bool wasInterruption}) {
    final tag = wasInterruption ? '[مقاطعة] ' : '';
    final permission = signal.allowQuestion ? '' : ' [لا تنهِ ردّك بسؤال هالمرة]';
    return '$tag$userMessage$permission';
  }

  String buildContinueMessage(ConversationSignal signal) {
    return '[استمرار طبيعي — اربط بجسر منطقي بين اللي قلته وبين فكرة أو قصة جديدة من فئة "${signal.topicCategory}" من الواقع العربي/الخليجي، بلا قفزة مفاجئة. ممنوع إنهاء الرد بسؤال]';
  }
}
