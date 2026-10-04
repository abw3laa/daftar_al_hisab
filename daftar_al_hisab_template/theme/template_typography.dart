import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateTypography {
  static TextTheme textTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    return GoogleFonts.ibmPlexSansArabicTextTheme().apply(
      bodyColor: color,
      displayColor: color,
    );
  }
}
