import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/order.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'combo_screen.dart';

/// Añade un producto desde la carta. Si no hay nada que elegir se añade sin más;
/// si lo hay (variante, extras, cantidad) sube una hoja corta con solo eso.
/// Los platos que van en menú siguen después con [ComboScreen].
Future<void> addToOrder(BuildContext context, MenuItem item, {bool ask = false}) async {
  final simple = !item.needsChoice && item.extras.isEmpty && !item.combo;
  if (simple && !ask) {
    HapticFeedback.lightImpact();
    OrderScope.read(context).add(item);
    toast(context, '${item.name} añadido al pedido');
    return;
  }
  final pick = await showModalBottomSheet<_Pick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DD.solid,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _ItemSheet(item: item),
  );
  if (pick == null || !context.mounted) return;
  var combo = const <String>[];
  var comboPrice = 0;
  if (item.combo) {
    final unit = item.price + pick.extras.fold<int>(0, (s, e) => s + e.price);
    final r = await ComboScreen.show(context, item, unit);
    if (r == null || !context.mounted) return;
    (combo: combo, price: comboPrice) = r;
  }
  HapticFeedback.mediumImpact();
  OrderScope.read(context).add(
    item,
    variant: pick.variant,
    extras: pick.extras,
    combo: combo,
    comboPrice: comboPrice,
    qty: pick.qty,
  );
  toast(context, '${pick.qty} × ${item.name}${combo.isEmpty ? '' : ' (menú)'} añadido al pedido');
}

typedef _Pick = ({String? variant, List<Extra> extras, int qty});

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.item});
  final MenuItem item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  String? _variant;
  final Set<Extra> _extras = {};
  int _qty = 1;

  int get _unit => widget.item.price + _extras.fold(0, (s, e) => s + e.price);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ready = !item.needsChoice || _variant != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
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
            const SizedBox(height: 18),
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.description, style: const TextStyle(color: DD.textDim, fontSize: 14, height: 1.4)),
            ],
            if (item.variants.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Elige una opción', style: TextStyle(color: DD.textDim, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in item.variants)
                    Pill(label: v, selected: _variant == v, onTap: () => setState(() => _variant = v)),
                ],
              ),
            ],
            if (item.extras.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Extras', style: TextStyle(color: DD.textDim, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in item.extras)
                    Pill(
                      label: '${e.name}  +${euros(e.price)}',
                      icon: _extras.contains(e) ? Icons.check : Icons.add,
                      selected: _extras.contains(e),
                      onTap: () => setState(() => _extras.contains(e) ? _extras.remove(e) : _extras.add(e)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: item.combo ? 'Continuar' : 'Añadir',
                    trailing: euros(_unit * _qty),
                    onTap: ready
                        ? () => Navigator.of(context).pop<_Pick>((
                            variant: _variant,
                            extras: _extras.toList(),
                            qty: _qty,
                          ))
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
