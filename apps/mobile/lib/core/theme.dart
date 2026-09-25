import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CLASSES.OS design tokens (mirrors apps/web/src/styles/os.css).
class OS {
  static const acc = Color(0xFF1B4DFF);
  static const accH = Color(0xFF0B37D8);
  static const violet = Color(0xFF6C29E0);
  static const hot = Color(0xFFFF5C38);
  static const lime = Color(0xFF00A96E);
  static const amb = Color(0xFFB27400);
  static const ink = Color(0xFF0A0C14);

  static const rSm = 12.0;
  static const r = 18.0;
  static const rLg = 24.0;

  static const featGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [acc, accH, violet],
    stops: [0, .55, 1],
  );
}

/// Theme-dependent surface colours, available via `context.os`.
@immutable
class OSColors extends ThemeExtension<OSColors> {
  const OSColors({
    required this.txt2,
    required this.txt3,
    required this.surf,
    required this.surf2,
    required this.canvas,
    required this.line,
    required this.accSoft,
    required this.hotSoft,
    required this.limeSoft,
    required this.ambSoft,
  });

  final Color txt2, txt3, surf, surf2, canvas, line, accSoft, hotSoft, limeSoft, ambSoft;

  static const light = OSColors(
    txt2: Color(0xFF4A5261),
    txt3: Color(0xFF8A93A3),
    surf: Colors.white,
    surf2: Color(0xFFF7F8FB),
    canvas: Color(0xFFF1F3F7),
    line: Color(0xFFE6E9EF),
    accSoft: Color(0xFFE8EDFF),
    hotSoft: Color(0xFFFFEBE6),
    limeSoft: Color(0xFFDCF7EC),
    ambSoft: Color(0xFFFFF2D6),
  );

  static const dark = OSColors(
    txt2: Color(0xFF9AA3B2),
    txt3: Color(0xFF69717F),
    surf: Color(0xFF13161F),
    surf2: Color(0xFF1A1E29),
    canvas: Color(0xFF0A0C14),
    line: Color(0xFF242938),
    accSoft: Color(0xFF141C3D),
    hotSoft: Color(0xFF2B1710),
    limeSoft: Color(0xFF0C2419),
    ambSoft: Color(0xFF2A2007),
  );

  @override
  OSColors copyWith() => this;

  @override
  OSColors lerp(OSColors? other, double t) => t < .5 ? this : (other ?? this);
}

extension OSContext on BuildContext {
  OSColors get os => Theme.of(this).extension<OSColors>()!;
}

TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -size * .04,
      height: 1.0,
      color: color,
    );

TextStyle mono(double size, {Color? color, FontWeight weight = FontWeight.w500}) =>
    GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? OSColors.dark : OSColors.light;
  final txt = brightness == Brightness.dark ? const Color(0xFFEDEFF4) : OS.ink;
  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: OS.acc,
      brightness: brightness,
      primary: OS.acc,
      error: OS.hot,
      surface: c.surf,
    ),
    textTheme: GoogleFonts.interTightTextTheme(base.textTheme).apply(
      bodyColor: txt,
      displayColor: txt,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: display(22, color: txt, weight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: c.surf,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OS.r)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: OS.acc,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OS.r)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surf,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OS.rSm),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OS.rSm),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OS.rSm),
        borderSide: const BorderSide(color: OS.acc, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.dark ? Colors.white : OS.ink,
      contentTextStyle: TextStyle(
        color: brightness == Brightness.dark ? OS.ink : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
