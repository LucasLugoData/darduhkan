import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../data/product_images.g.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/smoke.dart';

/// Lo elegido en [ComboScreen]: `combo` vacío si el plato va solo.
typedef ComboResult = ({List<String> combo, int price});

/// Pedido por pasos como en un quiosco de fast food: ¿menú o solo? →
/// acompañamiento → bebida → resumen. Al tocar una opción avanza sola.
/// Devuelve `null` si se sale sin elegir.
class ComboScreen extends StatefulWidget {
  const ComboScreen({super.key, required this.item, required this.unit});
  final MenuItem item;

  /// Precio unitario del plato con sus extras.
  final int unit;

  static Future<ComboResult?> show(BuildContext context, MenuItem item, int unit) =>
      Navigator.of(context).push<ComboResult>(
        PageRouteBuilder(
          transitionDuration: DD.medium,
          reverseTransitionDuration: DD.medium,
          pageBuilder: (_, _, _) => ComboScreen(item: item, unit: unit),
          transitionsBuilder: (_, a, _, child) {
            final c = CurvedAnimation(parent: a, curve: DD.curve);
            return FadeTransition(
              opacity: c,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(c),
                child: child,
              ),
            );
          },
        ),
      );

  @override
  State<ComboScreen> createState() => _ComboScreenState();
}

class _ComboScreenState extends State<ComboScreen> {
  static const _steps = ['Menú', 'Acompañamiento', 'Bebida', 'Resumen'];

  int _step = 0;
  bool _forward = true;
  ComboOption? _side;
  ComboOption? _drink;

  /// Opción recién tocada: se marca un instante antes de pasar al siguiente paso.
  Object? _flash;

  int get _total => widget.unit + (_step == 0 ? 0 : comboPrice + (_drink?.price ?? 0));

  void _go(int step) {
    HapticFeedback.selectionClick();
    setState(() {
      _forward = step > _step;
      _step = step;
      _flash = null;
    });
  }

  Future<void> _pick(Object option, VoidCallback apply) async {
    HapticFeedback.selectionClick();
    setState(() {
      apply();
      _flash = option;
    });
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (mounted) _go(_step + 1);
  }

  void _back() => _step == 0 ? Navigator.of(context).pop() : _go(_step - 1);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Smoke(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      RoundIconButton(icon: Icons.arrow_back, onTap: _back),
                      Expanded(
                        child: Text(
                          widget.item.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DD.brand(size: 13, spacing: 4),
                        ),
                      ),
                      RoundIconButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _stepper(),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: DD.medium,
                    switchInCurve: DD.curve,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, a) {
                      final incoming = child.key == ValueKey(_step);
                      final dx = (incoming == _forward ? 1 : -1) * 0.12;
                      return FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(key: ValueKey(_step), child: _page()),
                  ),
                ),
                _bottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepper() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        for (final (i, s) in _steps.indexed) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: DD.medium,
                curve: DD.curve,
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= _step ? DD.accent : DD.line,
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: DD.medium,
                curve: DD.curve,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _step ? DD.accent : Colors.transparent,
                  border: Border.all(color: i <= _step ? DD.accent : DD.line, width: 1.6),
                ),
                child: Center(
                  child: i < _step
                      ? const Icon(Icons.check, size: 15, color: DD.bg)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: i == _step ? DD.accent : DD.textDim,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s,
                style: TextStyle(fontSize: 10, color: i == _step ? DD.text : DD.textDim),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _title(String text, [String? sub]) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: DD.textDim, fontSize: 14)),
        ],
      ],
    ),
  );

  Widget _page() => switch (_step) {
    0 => ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _title('¿Lo quieres en menú?', 'Con acompañamiento y bebida por ${euros(comboPrice)} más'),
        FadeSlideIn(
          child: _Card(
            selected: _flash == 'menu',
            badge: 'Recomendado',
            onTap: () => _pick('menu', () {}),
            child: Column(
              children: [
                SizedBox(height: 140, child: _comboArt(comboSides.first, comboDrinks.first)),
                const SizedBox(height: 12),
                _label('Menú', '${widget.item.name} + acompañamiento + bebida', euros(widget.unit + comboPrice)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _Card(
            selected: false,
            onTap: () => Navigator.of(context).pop<ComboResult>((combo: const [], price: 0)),
            child: Row(
              children: [
                SizedBox.square(dimension: 84, child: _Photo(widget.item.imageKey, widget.item.icon)),
                const SizedBox(width: 14),
                Expanded(child: _label('Solo', 'Solo el plato', euros(widget.unit), start: true)),
              ],
            ),
          ),
        ),
      ],
    ),
    1 => _grid('Elige tu acompañamiento', 'Incluido en el menú', comboSides, _side, (o) => _side = o, columns: 2),
    2 => _grid('Elige tu bebida', 'Todas incluidas salvo indicación', comboDrinks, _drink, (o) => _drink = o),
    _ => ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _title('Tu menú'),
        FadeSlideIn(child: SizedBox(height: 200, child: _comboArt(_side!, _drink!))),
        const SizedBox(height: 18),
        _summaryRow('Menú ${widget.item.name}', euros(widget.unit + comboPrice), null),
        _summaryRow(_side!.name, 'Incluido', 1),
        _summaryRow(_drink!.name, _drink!.price == 0 ? 'Incluida' : '+${euros(_drink!.price)}', 2),
      ],
    ),
  };

  Widget _grid(
    String title,
    String sub,
    List<ComboOption> options,
    ComboOption? current,
    void Function(ComboOption) apply, {
    int columns = 3,
  }) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _title(title, sub)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverGrid.count(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 0.85 : 0.72,
            children: [
              for (final (i, o) in options.indexed)
                FadeSlideIn(
                  delay: Duration(milliseconds: 50 * i),
                  child: _Card(
                    selected: _flash == o || (_flash == null && current == o),
                    onTap: () => _pick(o, () => apply(o)),
                    child: Column(
                      children: [
                        Expanded(child: _Photo(o.imageKey, o.icon)),
                        const SizedBox(height: 8),
                        Text(
                          o.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o.price == 0 ? 'Incluido' : '+${euros(o.price)}',
                          style: TextStyle(color: o.price == 0 ? DD.textDim : DD.accent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Acompañamiento, plato y bebida en fila, escalados para caber siempre enteros.
  Widget _comboArt(ComboOption side, ComboOption drink) => LayoutBuilder(
    builder: (_, c) {
      final s = math.min(c.maxHeight, c.maxWidth / 2.4);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _sized(_Photo(side.imageKey, side.icon), s * 0.64),
          _sized(_Photo(widget.item.imageKey, widget.item.icon), s),
          _sized(_Photo(drink.imageKey, drink.icon), s * 0.74),
        ],
      );
    },
  );

  Widget _sized(Widget child, double s) => SizedBox.square(dimension: s, child: child);

  Widget _label(String title, String sub, String price, {bool start = false}) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: DD.textDim, fontSize: 13)),
          ],
        ),
      ),
      Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
    ],
  );

  Widget _summaryRow(String label, String value, int? editStep) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(color: DD.textDim, fontSize: 15)),
        if (editStep != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _go(editStep),
            child: const Text(
              'Cambiar',
              style: TextStyle(color: DD.accent, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: DD.line))),
    child: _step == 3
        ? PrimaryButton(
            label: 'Añadir menú al pedido',
            trailing: euros(_total),
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop<ComboResult>(
                (combo: [_side!.name, _drink!.name], price: comboPrice + _drink!.price),
              );
            },
          )
        : SizedBox(
            height: 58,
            child: Row(
              children: [
                const Text('Total', style: TextStyle(color: DD.textDim, fontSize: 15)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: DD.fast,
                  child: Text(
                    euros(_total),
                    key: ValueKey(_total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
  );
}

/// Tarjeta grande tocable; al elegirla se ilumina el borde y aparece un check.
class _Card extends StatelessWidget {
  const _Card({required this.child, required this.selected, required this.onTap, this.badge});
  final Widget child;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DD.fast,
        curve: DD.curve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? DD.surfaceHi : DD.surface,
          borderRadius: BorderRadius.circular(DD.radius),
          border: Border.all(color: selected ? DD.accent : DD.line, width: selected ? 2 : 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (badge != null)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: DD.accent, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    badge!,
                    style: const TextStyle(color: DD.bg, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: DD.fast,
                curve: Curves.easeOutBack,
                child: const CircleAvatar(
                  radius: 13,
                  backgroundColor: DD.accent,
                  child: Icon(Icons.check, size: 16, color: DD.bg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto transparente del producto, o su icono mientras no exista.
class _Photo extends StatelessWidget {
  const _Photo(this.imageKey, this.icon);
  final String imageKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (productImages.contains(imageKey)) {
      return Image.asset(
        'assets/products/$imageKey.webp',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
      );
    }
    return LayoutBuilder(
      builder: (_, c) => Center(
        child: Container(
          width: c.biggest.shortestSide * 0.8,
          height: c.biggest.shortestSide * 0.8,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: DD.surfaceHi),
          child: Icon(icon, size: c.biggest.shortestSide * 0.4, color: DD.silver),
        ),
      ),
    );
  }
}
