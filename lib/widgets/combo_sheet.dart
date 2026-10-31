import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../theme.dart';
import 'common.dart';

/// Lo elegido en [ComboSheet]: `combo` vacío si el plato va solo.
typedef ComboResult = ({List<String> combo, int price});

/// Pedido por pasos al estilo fast food: ¿solo o en menú? → acompañamiento →
/// bebida → resumen. Devuelve `null` si se cierra sin elegir.
class ComboSheet extends StatefulWidget {
  const ComboSheet({super.key, required this.item, required this.unit});
  final MenuItem item;

  /// Precio unitario del plato con sus extras, para mostrar los totales.
  final int unit;

  static Future<ComboResult?> show(BuildContext context, MenuItem item, int unit) =>
      showModalBottomSheet<ComboResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: DD.bg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => ComboSheet(item: item, unit: unit),
      );

  @override
  State<ComboSheet> createState() => _ComboSheetState();
}

class _ComboSheetState extends State<ComboSheet> {
  int _step = 0;
  String? _side;
  Extra? _drink;

  static const _titles = ['¿Solo o en menú?', 'Elige acompañamiento', 'Elige bebida', 'Tu menú'];

  int get _menuTotal => widget.unit + comboPrice + (_drink?.price ?? 0);

  void _next(VoidCallback pick) {
    HapticFeedback.selectionClick();
    setState(() {
      pick();
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: DD.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_step > 0)
                  RoundIconButton(icon: Icons.arrow_back, onTap: () => setState(() => _step--))
                else
                  const SizedBox(width: 44),
                Expanded(
                  child: Column(
                    children: [
                      Text(widget.item.name.toUpperCase(), style: DD.brand(size: 12, spacing: 4)),
                      const SizedBox(height: 4),
                      Text(_titles[_step], style: DD.script(size: 24, color: DD.silver)),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 8),
            if (_step > 0) _progress(),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: DD.medium,
              switchInCurve: DD.curve,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_step), child: _body()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() => Row(
    children: [
      for (var i = 1; i <= 3; i++) ...[
        if (i > 1) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: DD.medium,
            height: 3,
            decoration: BoxDecoration(
              color: i <= _step ? DD.accent : DD.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _body() => switch (_step) {
    0 => Row(
      children: [
        Expanded(
          child: _Choice(
            icon: widget.item.icon,
            title: 'Solo',
            subtitle: 'Solo el plato',
            price: euros(widget.unit),
            onTap: () => Navigator.of(context).pop<ComboResult>((combo: const [], price: 0)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Choice(
            icon: Icons.fastfood_outlined,
            title: 'Menú',
            subtitle: 'Con acompañamiento y bebida',
            price: euros(widget.unit + comboPrice),
            highlighted: true,
            onTap: () => _next(() {}),
          ),
        ),
      ],
    ),
    1 => Row(
      children: [
        for (final (i, s) in comboSides.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _Choice(
              icon: s == 'Patatas' ? Icons.fastfood_outlined : Icons.eco_outlined,
              title: s,
              subtitle: 'Incluido',
              selected: _side == s,
              onTap: () => _next(() => _side = s),
            ),
          ),
        ],
      ],
    ),
    2 => GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final d in comboDrinks)
          _Choice(
            icon: d.name == 'Red Bull' ? Icons.bolt_outlined : Icons.local_drink_outlined,
            title: d.name,
            subtitle: d.price == 0 ? 'Incluida' : '+${euros(d.price)}',
            selected: _drink == d,
            compact: true,
            onTap: () => _next(() => _drink = d),
          ),
      ],
    ),
    _ => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in [
          (widget.item.name, euros(widget.unit)),
          ('Menú: $_side', euros(comboPrice)),
          (_drink!.name, _drink!.price == 0 ? 'Incluida' : euros(_drink!.price)),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 15.5))),
                Text(value, style: const TextStyle(color: DD.textDim, fontSize: 15.5)),
              ],
            ),
          ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Añadir menú',
          trailing: euros(_menuTotal),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop<ComboResult>(
              (combo: [_side!, _drink!.name], price: comboPrice + _drink!.price),
            );
          },
        ),
      ],
    ),
  };
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.price,
    this.selected = false,
    this.highlighted = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? price;
  final VoidCallback onTap;
  final bool selected;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DD.fast,
        padding: EdgeInsets.all(compact ? 10 : 18),
        decoration: BoxDecoration(
          color: selected ? DD.surfaceHi : DD.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected || highlighted ? DD.accent : DD.line, width: selected ? 1.6 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 26 : 40, color: highlighted || selected ? DD.accent : DD.silver),
            SizedBox(height: compact ? 8 : 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 14 : 18),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: DD.textDim, fontSize: compact ? 11.5 : 12.5),
            ),
            if (price != null) ...[
              const SizedBox(height: 10),
              Text(price!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ],
        ),
      ),
    );
  }
}
