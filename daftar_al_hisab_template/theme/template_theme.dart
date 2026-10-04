import 'package:flutter/material.dart';

import 'template_colors.dart';
import 'template_typography.dart';

class TemplateTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: TemplateColors.primary,
      brightness: brightness,
      primary: TemplateColors.primary,
      secondary: TemplateColors.positive,
      error: TemplateColors.negative,
      surface: dark ? TemplateColors.darkSurface : TemplateColors.lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? TemplateColors.darkBackground : TemplateColors.lightBackground,
      textTheme: TemplateTypography.textTheme(brightness),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
            dark ? TemplateColors.darkBackground : TemplateColors.lightBackground,
        foregroundColor: dark ? Colors.white : const Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? TemplateColors.darkSurface : TemplateColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark ? TemplateColors.darkOutline : TemplateColors.lightOutline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? TemplateColors.darkSurface : TemplateColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? TemplateColors.darkOutline : TemplateColors.lightOutline,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor:
            dark ? TemplateColors.darkSurface : TemplateColors.lightSurface,
        indicatorColor: dark
            ? TemplateColors.primaryDark
            : const Color(0xFFE0E7FF),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.ibmPlexSansArabic(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
