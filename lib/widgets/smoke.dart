import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Reloj compartido: el humo y los degradados siguen el mismo tiempo en todas
/// las pantallas, así no "saltan" al navegar.
final _clock = Stopwatch()..start();
double get _seconds => _clock.elapsedMicroseconds / 1e6;

/// Mixin que emite el tiempo global en cada frame sin reconstruir widgets.
mixin _TimeTicker<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  final time = ValueNotifier<double>(_seconds);
  late final Ticker _ticker = createTicker((_) => time.value = _seconds);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    time.dispose();
    super.dispose();
  }
}

/// Fondo negro con nubes de humo de color que derivan lentamente.
class Smoke extends StatefulWidget {
  const Smoke({super.key, required this.child, this.intensity = 1});
  final Widget child;
  final double intensity;

  @override
  State<Smoke> createState() => _SmokeState();
}

class _SmokeState extends State<Smoke> with SingleTickerProviderStateMixin, _TimeTicker {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _SmokePainter(time, widget.intensity))),
        widget.child,
      ],
    );
  }
}

class _Blob {
  const _Blob(this.color, this.radius, this.cx, this.cy, this.ax, this.ay, this.fx, this.fy, this.phase);
  final Color color;
  final double radius, cx, cy, ax, ay, fx, fy, phase;
}

const _blobs = [
  _Blob(DD.smokeViolet, 0.95, 0.15, 0.10, 0.30, 0.18, 0.031, 0.023, 0.0),
  _Blob(DD.smokeTeal, 0.85, 0.90, 0.45, 0.25, 0.30, 0.019, 0.027, 1.7),
  _Blob(DD.smokeWine, 0.80, 0.25, 0.95, 0.30, 0.20, 0.025, 0.017, 3.1),
  _Blob(DD.smokeIndigo, 0.70, 0.70, 0.05, 0.28, 0.22, 0.021, 0.033, 4.4),
];

class _SmokePainter extends CustomPainter {
  _SmokePainter(this.time, this.intensity) : super(repaint: time);
  final ValueNotifier<double> time;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = DD.bg);
    final t = time.value * 2 * math.pi;
    final unit = math.max(size.width, size.height * 0.75);
    for (final b in _blobs) {
      final c = Offset(
        size.width * (b.cx + b.ax * math.sin(t * b.fx + b.phase)),
        size.height * (b.cy + b.ay * math.cos(t * b.fy + b.phase * 0.7)),
      );
      // La nube "respira": el radio oscila suavemente.
      final r = unit * b.radius * (0.9 + 0.1 * math.sin(t * 0.013 + b.phase));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: 0.55 * intensity),
              b.color.withValues(alpha: 0.18 * intensity),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    // Viñeta: oscurece los bordes para que el contenido mande.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [Colors.transparent, DD.bg.withValues(alpha: 0.65)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SmokePainter old) => old.intensity != intensity;
}

/// Texto con un degradado plata → lavanda → petróleo que se desliza.
class ShimmerText extends StatefulWidget {
  const ShimmerText(this.text, {super.key, required this.style, this.textAlign});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin, _TimeTicker {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: time,
      child: Text(
        widget.text,
        textAlign: widget.textAlign,
        style: widget.style.copyWith(color: Colors.white),
      ),
      builder: (_, t, child) {
        final shift = (t / 6) % 2; // 0..2
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment(-3 + 2 * shift, -0.3),
            end: Alignment(-1 + 2 * shift, 0.3),
            tileMode: TileMode.mirror,
            colors: DD.shimmer,
          ).createShader(r),
          child: child,
        );
      },
    );
  }
}
