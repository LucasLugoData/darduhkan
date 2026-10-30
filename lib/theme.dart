import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta Dar Dukhan: negro, humo de color en movimiento y cristal.
/// El único acento sólido es un crema cálido sobre negro.
abstract final class DD {
  static const bg = Color(0xFF050506);
  static const solid = Color(0xFF111113);

  /// Superficies de cristal: dejan ver el humo del fondo.
  static const surface = Color(0x0FFFFFFF);
  static const surfaceHi = Color(0x17FFFFFF);
  static const line = Color(0x14FFFFFF);
  static const text = Color(0xFFF2EFEA);
  static const textDim = Color(0xFF8C8A93);
  static const silver = Color(0xFFC9C9D2);

  /// Acento: crema (botones, selección). El texto encima va en [bg].
  static const accent = Color(0xFFEDE7DC);

  // Humo
  static const smokeViolet = Color(0xFF4A2F9E);
  static const smokeTeal = Color(0xFF0E5560);
  static const smokeWine = Color(0xFF6B1A44);
  static const smokeIndigo = Color(0xFF1D2C7A);
  static const shimmer = [Color(0xFFE9E6F2), Color(0xFFB7A6FF), Color(0xFF7FD3C8), Color(0xFFE6B7D0)];

  static const radius = 22.0;
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 420);
  static const slow = Duration(milliseconds: 900);
  static const curve = Curves.easeOutCubic;

  /// Marca: sans geométrica y espaciada, como el logotipo.
  static TextStyle brand({double size = 22, double spacing = 7}) => GoogleFonts.josefinSans(
    fontSize: size,
    letterSpacing: spacing,
    fontWeight: FontWeight.w500,
    color: text,
  );

  /// Títulos de sección: serif itálica, eco de la tipografía manuscrita de la carta.
  static TextStyle script({double size = 22, Color color = text}) => GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(surface: solid, primary: accent, onPrimary: bg, secondary: silver),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xF21A1A1F),
        contentTextStyle: GoogleFonts.manrope(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

String euros(int cents) {
  final e = cents ~/ 100;
  final c = (cents % 100).toString().padLeft(2, '0');
  return '$e,$c\u00A0€';
}
