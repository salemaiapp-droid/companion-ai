import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/voice_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/user_prefs.dart';
import 'theme/app_theme.dart';
import 'theme/brand_tokens.dart';

void main() {
  runApp(const TavoApp());
}

/// TAVO — application root.
class TavoApp extends StatelessWidget {
  const TavoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TavoBrand.name,
      debugShowCheckedModeBanner: false,
      theme: TavoTheme.dark,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _TavoRoot(),
    );
  }
}

/// Owns the top-level flow: splash → (welcome, only if first time) → Voice Home.
class _TavoRoot extends StatelessWidget {
  const _TavoRoot();

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: () async {
        final saved = await UserPrefs.load();
        if (!context.mounted) return;

        if (saved != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => VoiceHomeScreen(userName: saved.name)),
          );
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (welcomeContext) => WelcomeScreen(
              onComplete: (result) async {
                await UserPrefs.save(result);
                if (!welcomeContext.mounted) return;
                Navigator.of(welcomeContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => VoiceHomeScreen(userName: result.name),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}