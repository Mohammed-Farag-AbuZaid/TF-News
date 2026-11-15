import 'package:flutter/material.dart';

/// TF Unions Architectural Palette (`tf_news` — Calm Alabaster & Fjord Slate)
class TColors {
  TColors._();

  // Brand Core
  static const Color primary = Color(0xFF1B365D);       // Fjord Slate
  static const Color primaryDark = Color(0xFF132847);   // Deep Fjord Slate
  static const Color navyAlt = Color(0xFF1B365D);       // Elevated Slate Surface
  static const Color secondry = Color(0xFF0F766E);      // Botanical Teal Accent
  static const Color accent = Color(0xFF1B365D);

  // Typography & Ink
  static const Color textprimary = Color(0xFF161A22);   // Deep Ink
  static const Color textsecondry = Color(0xFF525866);  // Secondary Slate Ink
  static const Color textMuted = Color(0xFF767D8C);     // Muted Ink
  static const Color textwhite = Colors.white;

  // Background Surfaces
  static const Color light = Color(0xFFF3F2EE);         // Calm Warm Alabaster
  static const Color dark = Color(0xFF161A22);          // Quiet Ink Dark
  static const Color primaryBackground = Color(0xFFF3F2EE);

  // Containers & Cards
  static const Color lightContainer = Color(0xFFFFFFFF); // Crisp Widget White
  static const Color surfaceAlt = Color(0xFFEAE8E1);     // Recessed Control Well
  static Color darkContainer = const Color(0xFF1B365D);

  // Buttons
  static const Color buttonPrimary = Color(0xFF1B365D);
  static const Color buttonSecondary = Color(0xFF0F766E);
  static const Color buttonDisabled = Color(0xFFDCD9D0);

  // Structural Borders
  static const Color borderPrimary = Color(0xFFDFDDD6);
  static const Color borderSecondary = Color(0xFFDCD9D0);
  static const Color navyBorder = Color(0xFFDFDDD6);

  // Semantics
  static const Color error = Color(0xFFB91C1C);
  static const Color success = Color(0xFF0F766E);
  static const Color warning = Color(0xFFB45309);
  static const Color info = Color(0xFF1B365D);

  // Neutral Shades
  static const Color black = Color(0xFF161A22);
  static const Color darkerGrey = Color(0xFF1E293B);
  static const Color darkGrey = Color(0xFF525866);
  static const Color grey = Color(0xFF767D8C);
  static const Color softgrey = Color(0xFFEAE8E1);
  static const Color lightgrey = Color(0xFFF3F2EE);
  static const Color white = Color(0xFFFFFFFF);

  // Quiet Slate Band
  static const Gradient linearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B365D),
      Color(0xFF132847),
    ],
  );
}
