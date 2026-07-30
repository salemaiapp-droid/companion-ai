import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/brand_tokens.dart';

void main() {
  runApp(const TavoApp());
}

/// TAVO — application root.
///
/// Applies the brand [TavoTheme.dark], forces Arabic-first right-to-left
/// layout, and opens on the [SplashScreen]. The splash hands off via its
/// [SplashScreen.onComplete] callback — for now it lands on a temporary
/// placeholder home; swap that for the welcome/onboarding flow once it exists.
class TavoApp extends StatelessWidget {
  const TavoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TavoBrand.name,
      debugShowCheckedModeBanner: false,
      theme: TavoTheme.dark,
      // Arabic-first. Wrap the whole app RTL until full localization is added.
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: SplashScreen(
        onComplete: () {
          // TODO: replace with the welcome / onboarding flow once built.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const _PlaceholderHome()),
          );
        },
      ),
    );
  }
}

/// Temporary landing screen so the splash has somewhere to go while the real
/// welcome/onboarding flow is being built. Delete once that exists.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('مرحباً بك في TAVO'),
      ),
    );
  }
}
