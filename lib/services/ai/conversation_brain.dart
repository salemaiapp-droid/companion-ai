import 'topic_engine.dart';

class ConversationSignal {
  const ConversationSignal({
    required this.topicCategory,
    required this.allowQuestion,
    required this.energyLevel,
  });

  final String topicCategory;
  final bool allowQuestion;
  final int energyLevel;
}

class ConversationBrain {
  final TopicEngine _topics = TopicEngine();
  int _repliesSinceQuestion = 0;
  int _energyLevel = 3;

  bool _endsWithQuestion(String text) => text.trim().endsWith('؟');

  ConversationSignal onOpen() {
    return ConversationSignal(
      topicCategory: _topics.nextCategory(),
      allowQuestion: false,
      energyLevel: _energyLevel,
    );
  }

  ConversationSignal onUserReply(String userText, {required bool wasInterruption}) {
    if (wasInterruption) {
      _energyLevel = (_energyLevel + 1).clamp(1, 5);
    }
    return ConversationSignal(
      topicCategory: _topics.nextCategory(),
      allowQuestion: _repliesSinceQuestion >= 3,
      energyLevel: _energyLevel,
    );
  }

  ConversationSignal onSilence() {
    return ConversationSignal(
      topicCategory: _topics.nextCategory(),
      allowQuestion: false,
      energyLevel: _energyLevel,
    );
  }

  void recordAssistantReply(String text) {
    _repliesSinceQuestion = _endsWithQuestion(text) ? 0 : _repliesSinceQuestion + 1;
  }
}
