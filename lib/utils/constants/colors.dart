import 'package:flutter/material.dart';

/// TF Unions Architectural Palette (`tf_news` — TF Oxford & Stone)
class TColors {
  TColors._();

  // Brand Core
  static const Color primary = Color(0xFF14388C);       // TF Royal Cobalt
  static const Color primaryDark = Color(0xFF0A1931);   // Deep Oxford Navy
  static const Color navyAlt = Color(0xFF102447);       // Elevated Oxford Surface
  static const Color secondry = Color(0xFFC88A14);      // TF Academic Brass
  static const Color accent = Color(0xFF14388C);

  // Typography & Ink
  static const Color textprimary = Color(0xFF12161F);   // Deep Ink
  static const Color textsecondry = Color(0xFF4A5262);  // Secondary Slate Ink
  static const Color textMuted = Color(0xFF687082);     // Subdued Ink
  static const Color textwhite = Colors.white;

  // Background Surfaces
  static const Color light = Color(0xFFECEAE4);         // Warm Architectural Stone
  static const Color dark = Color(0xFF0A1931);          // Deep Oxford Navy
  static const Color primaryBackground = Color(0xFFECEAE4);

  // Containers & Cards
  static const Color lightContainer = Color(0xFFFFFFFF); // Crisp Architectural White
  static const Color surfaceAlt = Color(0xFFE2DFD7);     // Secondary Stone Well
  static Color darkContainer = const Color(0xFF102447);

  // Buttons
  static const Color buttonPrimary = Color(0xFF14388C);
  static const Color buttonSecondary = Color(0xFFC88A14);
  static const Color buttonDisabled = Color(0xFFCFCBC2);

  // Structural Borders
  static const Color borderPrimary = Color(0xFFCFCBC2);
  static const Color borderSecondary = Color(0xFFC8C3B8);
  static const Color navyBorder = Color(0xFF1E3A6D);

  // Semantics
  static const Color error = Color(0xFFB91C1C);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color info = Color(0xFF14388C);

  // Neutral Shades
  static const Color black = Color(0xFF12161F);
  static const Color darkerGrey = Color(0xFF1E293B);
  static const Color darkGrey = Color(0xFF4A5262);
  static const Color grey = Color(0xFF687082);
  static const Color softgrey = Color(0xFFE2DFD7);
  static const Color lightgrey = Color(0xFFECEAE4);
  static const Color white = Color(0xFFFFFFFF);

  // Navy Masthead Solid-Tone Band
  static const Gradient linearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A1931),
      Color(0xFF102447),
    ],
  );
}
