import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All colour decisions live here. Nothing elsewhere hardcodes a hex value.
@immutable
class AppColors {
  final Color accent;
  final Color accentHover;
  final Color accentSoft;
  final Color hot;
  final Color hotSoft;
  final Color lime;
  final Color limeSoft;
  final Color amber;
  final Color amberSoft;

  final Color ink;
  final Color text;
  final Color text2;
  final Color text3;
  final Color surface;
  final Color surface2;
  final Color canvas;
  final Color line;
  final Color line2;

  const AppColors({
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.hot,
    required this.hotSoft,
    required this.lime,
    required this.limeSoft,
    required this.amber,
    required this.amberSoft,
    required this.ink,
    required this.text,
    required this.text2,
    required this.text3,
    required this.surface,
    required this.surface2,
    required this.canvas,
    required this.line,
    required this.line2,
  });

  Color get accentGlow => accent.withOpacity(0.22);

  static const AppColors light = AppColors(
    accent: Color(0xFF1B4DFF),
    accentHover: Color(0xFF0B37D8),
    accentSoft: Color(0xFFE8EDFF),
    hot: Color(0xFFFF5C38),
    hotSoft: Color(0xFFFFEBE6),
    lime: Color(0xFF00A96E),
    limeSoft: Color(0xFFDCF7EC),
    amber: Color(0xFFB27400),
    amberSoft: Color(0xFFFFF2D6),
    ink: Color(0xFF0A0C14),
    text: Color(0xFF0A0C14),
    text2: Color(0xFF4A5261),
    text3: Color(0xFF8A93A3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F8FB),
    canvas: Color(0xFFF1F3F7),
    line: Color(0xFFE6E9EF),
    line2: Color(0xFFF0F2F6),
  );

  static const AppColors dark = AppColors(
    accent: Color(0xFF1B4DFF),
    accentHover: Color(0xFF4A78FF),
    accentSoft: Color(0xFF141C3D),
    hot: Color(0xFFFF5C38),
    hotSoft: Color(0xFF2B1710),
    lime: Color(0xFF00A96E),
    limeSoft: Color(0xFF0C2419),
    amber: Color(0xFFD9A441),
    amberSoft: Color(0xFF2A2007),
    ink: Color(0xFF05060B),
    text: Color(0xFFEDEFF4),
    text2: Color(0xFF9AA3B2),
    text3: Color(0xFF69717F),
    surface: Color(0xFF13161F),
    surface2: Color(0xFF1A1E29),
    canvas: Color(0xFF0A0C14),
    line: Color(0xFF242938),
    line2: Color(0xFF1C2130),
  );
}

/// Corner radii, from the prototype's --r scale.
class R {
  const R._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
}

/// Spacing scale.
class Gap {
  const Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 26;
}

/// Motion. Every transition in the app pulls its curve and duration from here.
class Motion {
  const Motion._();
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve ease = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration count = Duration(milliseconds: 900);
}

/// Typography. Three families, used strictly:
///   display -> Bricolage Grotesque (headings and big numerals)
///   body    -> Inter Tight
///   mono    -> IBM Plex Mono (times, roll numbers, any figure in a table)
///
/// If a font name ever fails to resolve in google_fonts, change it in this
/// one place rather than at the call sites.
class AppType {
  const AppType._();

  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w600, Color? color, double? height}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.08,
        letterSpacing: -size * 0.03,
      );

  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
      GoogleFonts.interTight(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.4,
      );

  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.3,
      );

  /// The small uppercase label that sits above every number in the app.
  static TextStyle label(Color color) => GoogleFonts.interTight(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.1,
        height: 1.2,
      );
}

/// Shadows, light and dark.
class Shadows {
  const Shadows._();

  static List<BoxShadow> one(Brightness b) => b == Brightness.dark
      ? const [BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1))]
      : const [
          BoxShadow(color: Color(0x0A0A0C14), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x080A0C14), blurRadius: 6, offset: Offset(0, 2)),
        ];

  static List<BoxShadow> two(Brightness b) => b == Brightness.dark
      ? const [BoxShadow(color: Color(0x6B000000), blurRadius: 28, offset: Offset(0, 8))]
      : const [
          BoxShadow(color: Color(0x0F0A0C14), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0F0A0C14), blurRadius: 32, offset: Offset(0, 12)),
        ];

  static List<BoxShadow> three(Brightness b) => b == Brightness.dark
      ? const [BoxShadow(color: Color(0x99000000), blurRadius: 70, offset: Offset(0, 24))]
      : const [BoxShadow(color: Color(0x330A0C14), blurRadius: 60, offset: Offset(0, 20))];
}

/// Colour access without passing AppColors down every constructor.
extension AppColorContext on BuildContext {
  AppColors get c =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  Brightness get brightness => Theme.of(this).brightness;

  bool get isCompact => MediaQuery.sizeOf(this).width < 900;
}
