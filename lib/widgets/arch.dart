import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme.dart';

/// Arco de herradura apuntado, la silueta de la marca Dar Dukhan.
Path archPath(Size s, {double cornerRadius = 0.16}) {
  final w = s.width, h = s.height;
  final r = w * cornerRadius;
  final shoulder = (w * 0.62).clamp(0.0, h * 0.5);
  // Empieza en el centro de la base: así el trazo animado sube por ambos lados
  // y se cierra en la punta.
  return Path()
    ..moveTo(w / 2, h)
    ..lineTo(w - r, h)
    ..quadraticBezierTo(w, h, w, h - r)
    ..lineTo(w, shoulder)
    ..cubicTo(w, shoulder * 0.42, w * 0.56, shoulder * 0.34, w * 0.5, 0)
    ..cubicTo(w * 0.44, shoulder * 0.34, 0, shoulder * 0.42, 0, shoulder)
    ..lineTo(0, h - r)
    ..quadraticBezierTo(0, h, r, h)
    ..close();
}

class ArchClipper extends CustomClipper<Path> {
  const ArchClipper();
  @override
  Path getClip(Size size) => archPath(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Contorno del arco que se dibuja progresivamente (0 → 1).
class ArchOutlinePainter extends CustomPainter {
  ArchOutlinePainter({required this.progress, this.color = DD.silver, this.stroke = 2});
  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = archPath(Size(size.width - stroke, size.height - stroke));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [color, color.withValues(alpha: 0.35), color],
        [0, 0.5, 1],
      );
    canvas.translate(stroke / 2, stroke / 2);
    for (final m in path.computeMetrics()) {
      final half = m.length / 2 * progress;
      canvas.drawPath(m.extractPath(0, half), paint);
      canvas.drawPath(m.extractPath(m.length - half, m.length), paint);
    }
  }

  @override
  bool shouldRepaint(ArchOutlinePainter old) => old.progress != progress || old.color != color;
}

/// Silueta minimalista de una shisha.
class HookahPainter extends CustomPainter {
  HookahPainter({this.color = DD.text});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 160);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    // Cazoleta y bandeja
    canvas.drawPath(
      Path()
        ..moveTo(41, 6)
        ..lineTo(59, 6)
        ..lineTo(54, 19)
        ..lineTo(46, 19)
        ..close(),
      fill,
    );
    canvas.drawRRect(RRect.fromLTRBR(30, 21, 70, 25.5, const Radius.circular(3)), fill);
    // Mástil con abalorios
    canvas.drawRect(const Rect.fromLTRB(47.5, 25, 52.5, 100), fill);
    canvas.drawOval(const Rect.fromLTRB(43, 38, 57, 52), fill);
    canvas.drawOval(const Rect.fromLTRB(44, 60, 56, 72), fill);
    canvas.drawRRect(RRect.fromLTRBR(42, 84, 58, 89, const Radius.circular(2)), fill);
    // Válvula
    canvas.drawLine(const Offset(52, 80), const Offset(64, 74), stroke);
    // Jarrón
    canvas.drawPath(
      Path()
        ..moveTo(45, 98)
        ..cubicTo(45, 112, 30, 118, 30, 134)
        ..cubicTo(30, 142, 36, 146, 50, 146)
        ..cubicTo(64, 146, 70, 142, 70, 134)
        ..cubicTo(70, 118, 55, 112, 55, 98)
        ..close(),
      fill,
    );
    canvas.drawRRect(RRect.fromLTRBR(32, 147, 68, 152, const Radius.circular(2)), fill);
    // Manguera
    canvas.drawPath(
      Path()
        ..moveTo(47, 80)
        ..cubicTo(36, 70, 14, 62, 14, 84)
        ..lineTo(14, 150),
      stroke,
    );
    canvas.drawRRect(RRect.fromLTRBR(11, 118, 17, 132, const Radius.circular(2)), fill);
  }

  @override
  bool shouldRepaint(HookahPainter old) => old.color != color;
}

/// Ilustración de un producto: arco con brillo del color de su categoría.
class ItemArt extends StatelessWidget {
  const ItemArt({super.key, required this.item, this.size = const Size(56, 66), this.glow = 1});

  final MenuItem item;
  final Size size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final tint = item.category.tint;
    final glyph = size.width * 0.46;
    return SizedBox.fromSize(
      size: size,
      child: ClipPath(
        clipper: const ArchClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.35),
              radius: 0.95,
              colors: [
                tint.withValues(alpha: 0.42 * glow),
                tint.withValues(alpha: 0.10 * glow),
                DD.surfaceHi,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: Align(
            alignment: const Alignment(0, 0.4),
            child: item.category.art == ArtKind.hookah
                ? CustomPaint(
                    size: Size(glyph * 0.62, glyph),
                    painter: HookahPainter(color: DD.text.withValues(alpha: 0.92)),
                  )
                : Icon(item.icon, size: glyph, color: DD.text.withValues(alpha: 0.92)),
          ),
        ),
      ),
    );
  }
}
