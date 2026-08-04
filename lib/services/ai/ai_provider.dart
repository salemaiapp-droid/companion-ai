/// TAVO — AI Provider abstraction.
abstract class AiProvider {
  Future<String> complete(
    List<Map<String, String>> messages, {
    double temperature = 0.9,
    double presencePenalty = 0.9,
    double frequencyPenalty = 0.4,
    int maxTokens = 250,
  });
}