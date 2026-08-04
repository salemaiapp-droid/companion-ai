class VoiceDirector {
  String prepare(String rawText) {
    return rawText.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
