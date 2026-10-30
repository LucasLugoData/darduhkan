import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../screens/cart_screen.dart';
import '../state/order.dart';
import '../theme.dart';

/// Aparición con desvanecido y desplazamiento, opcionalmente escalonada.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 18});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: DD.medium);
  late final _a = CurvedAnimation(parent: _c, curve: DD.curve);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _a.value,
      child: Transform.translate(offset: Offset(0, widget.offset * (1 - _a.value)), child: child),
    ),
  );
}

/// Feedback táctil al pulsar: se encoge ligeramente.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _set(true),
    onTapCancel: () => _set(false),
    onTapUp: (_) => _set(false),
    onTap: widget.onTap == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            widget.onTap!();
          },
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: DD.fast,
      curve: DD.curve,
      child: widget.child,
    ),
  );
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, this.onTap, this.size = 46, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DD.surface,
          shape: BoxShape.circle,
          border: Border.all(color: DD.line),
        ),
        child: Icon(icon, size: size * 0.44, color: DD.text),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Botón del pedido con contador animado.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final order = OrderScope.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RoundIconButton(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'Tu pedido',
          onTap: () => Navigator.of(context).push(CartScreen.route()),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: AnimatedSwitcher(
            duration: DD.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: order.count == 0
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(order.count),
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: DD.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DD.bg, width: 2),
                    ),
                    child: Text(
                      '${order.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DD.bg),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.trailing, this.onTap, this.loading = false});
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: DD.fast,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: onTap == null ? DD.surfaceHi : DD.accent,
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            if (onTap != null)
              BoxShadow(color: DD.accent.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 6)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: DD.fast,
          child: loading
              ? const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: DD.bg),
                  ),
                )
              : Row(
                  key: ValueKey(label + (trailing ?? '')),
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        textAlign: trailing == null ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: onTap == null ? DD.textDim : DD.bg,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: DD.bg),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.compact = false,
  });
  final int value;
  final int min;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = compact ? 30.0 : 40.0;
    Widget btn(IconData i, int delta, bool enabled) => Pressable(
      onTap: enabled ? () => onChanged(value + delta) : null,
      child: SizedBox.square(
        dimension: s,
        child: Icon(i, size: s * 0.5, color: enabled ? DD.text : DD.textDim.withValues(alpha: 0.4)),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: DD.surface,
        borderRadius: BorderRadius.circular(s),
        border: Border.all(color: DD.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(min == 0 && value <= 1 ? Icons.delete_outline : Icons.remove, -1, value > min),
          SizedBox(
            width: compact ? 22 : 28,
            child: AnimatedSwitcher(
              duration: DD.fast,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 14 : 16),
              ),
            ),
          ),
          btn(Icons.add, 1, true),
        ],
      ),
    );
  }
}

/// Píldora seleccionable (variantes, extras, categorías).
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.selected, this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DD.fast,
        curve: DD.curve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? DD.text : DD.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? DD.text : DD.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: selected ? DD.bg : DD.textDim),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: selected ? DD.bg : DD.text),
            ),
          ],
        ),
      ),
    );
  }
}

void toast(BuildContext context, String msg, {IconData icon = Icons.check_circle_outline}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1600),
        // Por encima de la barra inferior (pedido / añadir).
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        content: Row(
          children: [
            Icon(icon, color: DD.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
}
