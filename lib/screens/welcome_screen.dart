import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';
import 'menu_screen.dart';

const _tables = 30;

/// Bienvenida: el arco se dibuja, aparece la marca y el cliente elige su mesa.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward();
  late final _draw = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
  );
  late final _logo = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.85, curve: DD.curve),
  );
  late PageController _pages;
  late int _table;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _table = OrderScope.read(context).table ?? 1;
    _pages = PageController(viewportFraction: 0.2, initialPage: _table - 1);
  }

  @override
  void dispose() {
    _intro.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _enter() {
    OrderScope.read(context).table = _table;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: DD.slow,
        pageBuilder: (_, a, _) => const MenuScreen(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: DD.curve),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final archW = (c.maxWidth * 0.5).clamp(160.0, 230.0);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _intro,
                      builder: (_, _) => SizedBox(
                        width: archW,
                        height: archW * 1.3,
                        child: CustomPaint(
                          painter: ArchOutlinePainter(progress: _draw.value, stroke: 2.4),
                          child: Opacity(
                            opacity: _logo.value,
                            child: Transform.scale(
                              scale: 0.85 + 0.15 * _logo.value,
                              child: Align(
                                alignment: const Alignment(0, 0.35),
                                child: CustomPaint(
                                  size: Size(archW * 0.32, archW * 0.52),
                                  painter: HookahPainter(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _logo,
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          Text('DAR DUKHAN', style: DD.brand(size: 26, spacing: 9)),
                          const SizedBox(height: 8),
                          Text(
                            'Bar · Shisha · Lounge',
                            style: TextStyle(color: DD.textDim, letterSpacing: 2, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 1300),
                      child: Column(
                        children: [
                          Text('¿En qué mesa estás?', style: DD.script(size: 26)),
                          const SizedBox(height: 18),
                          _tablePicker(),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: PrimaryButton(
                              label: 'Ver la carta',
                              trailing: 'Mesa $_table',
                              onTap: _enter,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Alcohol y shisha solo para mayores de 18 años',
                            style: TextStyle(color: DD.textDim.withValues(alpha: 0.7), fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tablePicker() {
    return SizedBox(
      height: 84,
      child: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.25, 0.75, 1],
        ).createShader(r),
        child: PageView.builder(
          controller: _pages,
          itemCount: _tables,
          onPageChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => _table = i + 1);
          },
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pages,
            builder: (_, _) {
              final page = _pages.hasClients && _pages.position.haveDimensions
                  ? _pages.page!
                  : (_table - 1).toDouble();
              final d = (page - i).abs().clamp(0.0, 1.0);
              final selected = d < 0.5;
              return GestureDetector(
                onTap: () => _pages.animateToPage(i, duration: DD.medium, curve: DD.curve),
                child: Center(
                  child: Transform.scale(
                    scale: 1 - d * 0.35,
                    child: Container(
                      width: 66,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        shape: const _ArchShape(),
                        color: selected ? DD.ember : DD.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : DD.textDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArchShape extends ShapeBorder {
  const _ArchShape();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => archPath(rect.size).shift(rect.topLeft);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}
