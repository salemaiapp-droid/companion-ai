/// TAVO — AI Provider abstraction.
///
/// The rest of the app never talks to OpenAI/Groq/Gemini/etc. directly —
/// it always goes through this interface. Swapping providers means writing
/// one new class here, zero changes anywhere else in the app.
abstract class AiProvider {
  Future<String> complete(
    List<Map<String, String>> messages, {
    double temperature = 0.9,
    double presencePenalty = 0.9,
    double frequencyPenalty = 0.4,
    int maxTokens = 400,
  });
}