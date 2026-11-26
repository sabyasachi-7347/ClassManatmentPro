import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      surface: c.surface,
      error: c.hot,
    ),
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTightTextTheme(base.textTheme).apply(
      bodyColor: c.text,
      displayColor: c.text,
    ),
    dividerTheme: DividerThemeData(color: c.line2, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.text2, size: 20),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.sm),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.sm),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.sm),
        borderSide: BorderSide(color: c.accent, width: 1.6),
      ),
      hintStyle: AppType.body(13.5, color: c.text3),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brightness == Brightness.dark ? Colors.white : c.ink,
      contentTextStyle: AppType.body(
        13,
        color: brightness == Brightness.dark ? c.ink : Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
  );
}
