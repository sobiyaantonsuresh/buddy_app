
import 'package:flutter/material.dart';

/// Official BUDDY website design colours.
/// Used for the Flutter companion app's LIGHT mode.
class BuddyTheme {
  BuddyTheme._();

  static const Color cream = Color(0xFFF5F0E5);
  static const Color paper = Color(0xFFFFFDF8);
  static const Color ink = Color(0xFF173630);
  static const Color forest = Color(0xFF173F37);
  static const Color mint = Color(0xFFDCEFE5);
  static const Color softMint = Color(0xFFA8D6C0);
  static const Color coral = Color(0xFFED7666);
  static const Color yellow = Color(0xFFEFBD52);
  static const Color blue = Color(0xFF6F8ECB);
  static const Color border = Color(0xFFC9D3C9);
  static const Color muted = Color(0xFF65766F);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: forest,
      onPrimary: paper,
      secondary: coral,
      onSecondary: ink,
      surface: paper,
      onSurface: ink,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      primaryColor: forest,
      cardColor: paper,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }
}
