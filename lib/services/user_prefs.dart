import 'package:shared_preferences/shared_preferences.dart';

import '../screens/welcome_screen.dart';

/// TAVO — persisted user preferences.
///
/// Stores what onboarding collects (name, language, tone) so it survives
/// app restarts. Backed by [SharedPreferences] — simple key/value, no server.
///
/// Usage:
///   await UserPrefs.save(result);            // after onboarding completes
///   final prefs = await UserPrefs.load();     // on app start
///   final done = await UserPrefs.hasCompletedOnboarding();
abstract class UserPrefs {
  static const _keyName = 'tavo_user_name';
  static const _keyLanguage = 'tavo_user_language';
  static const _keyTone = 'tavo_user_tone';

  /// Save the onboarding result. Call this once, right when onboarding
  /// finishes (in [WelcomeScreen.onComplete]).
  static Future<void> save(OnboardingResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, result.name);
    await prefs.setString(_keyLanguage, result.language.name);
    await prefs.setString(_keyTone, result.tone.name);
  }

  /// Load the saved preferences, or null if onboarding was never completed.
  static Future<OnboardingResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final languageStr = prefs.getString(_keyLanguage);
    final toneStr = prefs.getString(_keyTone);

    if (name == null || languageStr == null || toneStr == null) {
      return null;
    }

    return OnboardingResult(
      name: name,
      language: TavoLanguage.values.firstWhere(
        (l) => l.name == languageStr,
        orElse: () => TavoLanguage.arabic,
      ),
      tone: TavoTone.values.firstWhere(
        (t) => t.name == toneStr,
        orElse: () => TavoTone.friend,
      ),
    );
  }

  /// Quick check without loading full data — useful to decide whether to
  /// show the splash → welcome flow or skip straight to the main experience.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyName);
  }

  /// Clear saved preferences (e.g. for a "reset onboarding" / logout action).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyTone);
  }
}
