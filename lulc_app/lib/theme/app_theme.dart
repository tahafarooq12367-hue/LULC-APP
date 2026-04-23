import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepForest = Color(0xFF1B4332);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color midGreen = Color(0xFF40916C);
  static const Color lightGreen = Color(0xFF74C69D);
  static const Color paleGreen = Color(0xFFD8F3DC);
  static const Color deepOcean = Color(0xFF023E8A);
  static const Color oceanBlue = Color(0xFF0077B6);
  static const Color skyBlue = Color(0xFF00B4D8);
  static const Color lightSky = Color(0xFF90E0EF);
  static const Color earthBrown = Color(0xFF6B4226);
  static const Color sandTan = Color(0xFFD4A373);
  static const Color darkSurface = Color(0xFF0D1B2A);
  static const Color cardSurface = Color(0xFF1A2E3B);
  static const Color cardBorder = Color(0xFF2A4055);
  static const Color textPrimary = Color(0xFFE8F4F8);
  static const Color textSecondary = Color(0xFF8BAFC4);
  static const Color accentGold = Color(0xFFF4A261);

  static const Map<String, Color> classColors = {
    'Forest': Color(0xFF2D6A4F),
    'Urban': Color(0xFF6B7280),
    'Water': Color(0xFF0077B6),
    'Agriculture': Color(0xFFD4A017),
    'Barren Land': Color(0xFFD4A373),
  };

  static const Map<String, IconData> classIcons = {
    'Forest': Icons.forest_rounded,
    'Urban': Icons.location_city_rounded,
    'Water': Icons.water_rounded,
    'Agriculture': Icons.grass_rounded,
    'Barren Land': Icons.landscape_rounded,
  };

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: midGreen,
        secondary: skyBlue,
        surface: cardSurface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: midGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: midGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
      cardTheme: const CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: cardBorder),
        ),
      ),
    );
  }
}
