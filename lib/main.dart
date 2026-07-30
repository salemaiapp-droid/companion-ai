import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'theme/brand_tokens.dart';

void main() {
  runApp(const TavoApp());
}

/// TAVO — application root.
///
/// Applies the brand [TavoTheme.dark] and forces Arabic-first RTL. The actual
/// screen flow lives in [_TavoRoot], which is built *under* [MaterialApp] so its
/// context has a Navigator to push/replace with.
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

/// Owns the top-level flow: splash → welcome → (placeholder) home.
/// Because this widget sits below [MaterialApp], `context` here is under a
/// [Navigator], so pushReplacement works.
class _TavoRoot extends StatelessWidget {
  const _TavoRoot();

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (welcomeContext) => WelcomeScreen(
              onComplete: (result) {
                Navigator.of(welcomeContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => _PlaceholderHome(name: result.name),
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

/// Temporary landing screen until the real main experience is built.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final who = name.isEmpty ? '' : '، $name';
    return Scaffold(
      body: Center(child: Text('مرحباً بك في TAVO$who')),
    );
  }
}
