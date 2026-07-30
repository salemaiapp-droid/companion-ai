import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// TAVO — App theme.
///
/// Dark and voice-first. Built entirely on [TavoColors], [TavoGradients]
/// and [TavoType] so the whole app stays in sync with the brand identity.
///
/// Arabic-first: the default font is IBM Plex Sans Arabic, with Satoshi as
/// the Latin fallback. Numerals stay Latin everywhere.
///
/// Usage:
///   MaterialApp(
///     theme: TavoTheme.dark,
///     locale: const Locale('ar'),
///     ...
///   )
abstract class TavoTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: TavoColors.cyan, // the voice / the glow
      onPrimary: TavoColors.voidBg, // dark text on bright cyan
      secondary: TavoColors.purple, // the core / memory accents
      onSecondary: TavoColors.text,
      tertiary: TavoColors.teal,
      onTertiary: TavoColors.voidBg,
      surface: TavoColors.surface,
      onSurface: TavoColors.text,
      error: Color(0xFFFF5A6E),
      onError: TavoColors.text,
      outline: TavoColors.muted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: TavoColors.voidBg,
      canvasColor: TavoColors.voidBg,
      splashColor: TavoColors.cyan.withValues(alpha: 0.12),
      highlightColor: TavoColors.cyan.withValues(alpha: 0.06),

      // Arabic-first, Latin fallback. Latin numerals by default.
      fontFamily: TavoType.arabic,
      fontFamilyFallback: const [TavoType.latin],
      textTheme: _textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: TavoColors.voidBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: TavoColors.text,
        titleTextStyle: TextStyle(
          fontFamily: TavoType.arabic,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TavoColors.text,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF18202E),
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: TavoColors.text, size: 24),

      // Cards / sheets sit on the elevated surface tone.
      cardTheme: CardThemeData(
        color: TavoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // Default filled button = solid cyan. The gradient is reserved for the
      // primary CTA only — use [TavoGradientButton] for that, not this.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TavoColors.cyan,
          foregroundColor: TavoColors.voidBg,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: TavoType.arabic,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TavoColors.text,
          side: const BorderSide(color: TavoColors.muted, width: 1),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: TavoColors.cyan),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TavoColors.surface,
        hintStyle: const TextStyle(color: TavoColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TavoColors.cyan, width: 1.5),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: TavoColors.surface,
        contentTextStyle: TextStyle(color: TavoColors.text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    // Wordmark / hero — Latin geometric (Satoshi).
    displayLarge: TextStyle(
      fontFamily: TavoType.latin,
      fontSize: 44,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
      color: TavoColors.text,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: TavoColors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: TavoColors.text,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: TavoColors.text),
    bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: TavoColors.text),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: TavoColors.text,
    ),
    bodySmall: TextStyle(fontSize: 12, height: 1.5, color: TavoColors.muted),
  );
}

/// The primary call-to-action button, filled with the signature gradient
/// (#35E7FF → #A45CFF). Use this ONLY for the single primary action on a
/// screen — the gradient loses its meaning if it is everywhere.
class TavoGradientButton extends StatelessWidget {
  const TavoGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: TavoGradients.signature,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: TavoColors.voidBg,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: TavoType.arabic,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
