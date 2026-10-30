import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta Dar Dukhan: negro profundo, plata de la marca y un acento brasa
/// (el naranja salmón de las referencias, que aquí evoca el carbón de la shisha).
abstract final class DD {
  static const bg = Color(0xFF0A0A0B);
  static const surface = Color(0xFF141416);
  static const surfaceHi = Color(0xFF1C1C1F);
  static const line = Color(0xFF29292D);
  static const text = Color(0xFFF4F1EC);
  static const textDim = Color(0xFF8E8C88);
  static const silver = Color(0xFFC9C9CE);
  static const ember = Color(0xFFFF6A3D);
  static const emberSoft = Color(0xFFFF8F6B);

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
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: ember,
        onPrimary: Colors.white,
        secondary: silver,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHi,
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
