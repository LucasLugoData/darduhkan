import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.order});
  final PlacedOrder order;

  static Route<void> route(PlacedOrder order) => PageRouteBuilder(
    transitionDuration: DD.slow,
    pageBuilder: (_, _, _) => ConfirmationScreen(order: order),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  );

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final _draw = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.55, curve: Curves.easeInOutCubic),
  );
  late final _fill = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 0.8, curve: DD.curve),
  );
  late final _check = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.6, 1, curve: Curves.elasticOut),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), HapticFeedback.heavyImpact);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) => SizedBox(
                  width: 150,
                  height: 195,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(1.2),
                          child: ClipPath(
                            clipper: const ArchClipper(),
                            child: ColoredBox(color: DD.ember.withValues(alpha: 0.16 * _fill.value)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ArchOutlinePainter(progress: _draw.value, color: DD.ember, stroke: 2.4),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0, 0.3),
                        child: Transform.scale(
                          scale: _check.value,
                          child: const Icon(Icons.check_rounded, size: 64, color: DD.ember),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 700),
                child: Column(
                  children: [
                    Text('¡Pedido enviado!', style: DD.script(size: 34)),
                    const SizedBox(height: 8),
                    Text(
                      'Pedido #${o.number} · Mesa ${o.table}',
                      style: const TextStyle(
                        color: DD.textDim,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ya lo están preparando en barra.\nTe lo llevamos a la mesa en unos minutos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DD.textDim, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 900),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DD.surface,
                    borderRadius: BorderRadius.circular(DD.radius),
                    border: Border.all(color: DD.line),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final l in o.lines)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '${l.qty}×',
                                      style: const TextStyle(color: DD.ember, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l.detail.isEmpty ? l.item.name : '${l.item.name} · ${l.detail}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(euros(l.total), style: const TextStyle(color: DD.textDim)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(color: DD.line, height: 22),
                      Row(
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(
                            euros(o.total),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeSlideIn(
                delay: const Duration(milliseconds: 1100),
                child: PrimaryButton(label: 'Seguir pidiendo', onTap: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
