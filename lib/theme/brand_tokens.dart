import 'package:flutter/material.dart';

/// TAVO — Brand tokens.
///
/// Single source of truth for the visual identity ("light orb").
/// Do not hardcode brand colors anywhere else; reference these tokens.
///
/// Type: Satoshi (Latin) + IBM Plex Sans Arabic (Arabic).
/// Numerals: always Latin.
abstract class TavoColors {
  // Surfaces
  static const Color voidBg = Color(0xFF050506); // OLED base — the dark before the light
  static const Color surface = Color(0xFF0B1220); // cards, sheets, elevated
  static const Color deep = Color(0xFF0F305E); // deep supporting tone
  static const Color petrol = Color(0xFF174B64); // supporting depth

  // Brand
  static const Color teal = Color(0xFF00C2C7); // calmer cyan for large fills
  static const Color cyan = Color(0xFF35E7FF); // PRIMARY — the voice / the glow
  static const Color purple = Color(0xFFA45CFF); // ACCENT — the core / memory moments

  // Text
  static const Color text = Color(0xFFF2F4F8);
  static const Color muted = Color(0xFF8B8F98);
}

abstract class TavoGradients {
  /// Signature gradient — reserved for the orb, the splash, and the primary CTA only.
  /// Overuse kills its meaning.
  static const LinearGradient signature = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [TavoColors.cyan, TavoColors.purple],
  );
}

abstract class TavoType {
  static const String latin = 'Satoshi';
  static const String arabic = 'IBMPlexSansArabic'; // alt: 'Tajawal'
}

abstract class TavoBrand {
  static const String name = 'TAVO';
  static const String taglineEn = 'Never Talk Alone';
  static const String taglineAr = 'لن تتحدّث وحدك أبداً';
  static const String taglineSecondaryEn = 'Always Here';
  static const String taglineSecondaryAr = 'هنا دائمًا';
}
