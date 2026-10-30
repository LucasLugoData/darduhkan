import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';
import 'confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
    transitionDuration: DD.medium,
    reverseTransitionDuration: DD.medium,
    pageBuilder: (_, _, _) => const CartScreen(),
    transitionsBuilder: (_, a, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: DD.curve, reverseCurve: Curves.easeInCubic)),
      child: child,
    ),
  );

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final _note = TextEditingController(text: OrderScope.read(context).note);
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final order = OrderScope.read(context);
    order.note = _note.text.trim();
    setState(() => _sending = true);
    HapticFeedback.mediumImpact();
    final placed = await order.submit();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(ConfirmationScreen.route(placed));
  }

  @override
  Widget build(BuildContext context) {
    final order = OrderScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('TU PEDIDO', style: DD.brand(size: 13, spacing: 5)),
                        const SizedBox(height: 3),
                        Text(
                          'Mesa ${order.table ?? '-'}',
                          style: const TextStyle(color: DD.textDim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(duration: DD.medium, child: order.isEmpty ? _empty() : _list(order)),
            ),
            if (!order.isEmpty) _summary(order),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90,
            height: 116,
            child: CustomPaint(painter: ArchOutlinePainter(progress: 1, color: DD.line, stroke: 2)),
          ),
          const SizedBox(height: 20),
          Text('Aún no has pedido nada', style: DD.script(size: 24)),
          const SizedBox(height: 6),
          const Text('Explora la carta y añade lo que te apetezca', style: TextStyle(color: DD.textDim)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: PrimaryButton(label: 'Ver la carta', onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }

  Widget _list(Order order) {
    final lines = order.lines;
    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final (i, line) in lines.indexed)
          FadeSlideIn(
            key: ValueKey(line.key),
            delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
            child: Dismissible(
              key: ValueKey('d-${line.key}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                HapticFeedback.lightImpact();
                order.remove(line);
              },
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.only(right: 24),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: DD.ember.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DD.radius),
                ),
                child: const Icon(Icons.delete_outline, color: DD.ember),
              ),
              child: _LineTile(line: line, order: order),
            ),
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          maxLines: 3,
          minLines: 1,
          onChanged: (v) => order.note = v,
          decoration: InputDecoration(
            hintText: 'Nota para la barra (alergias, sin hielo…)',
            hintStyle: const TextStyle(color: DD.textDim, fontSize: 14),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: DD.textDim),
            filled: true,
            fillColor: DD.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: DD.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: DD.silver),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Desliza un producto a la izquierda para quitarlo',
          textAlign: TextAlign.center,
          style: TextStyle(color: DD.textDim, fontSize: 12),
        ),
      ],
    );
  }

  Widget _summary(Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: DD.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: DD.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${order.count} ${order.count == 1 ? 'artículo' : 'artículos'}',
                style: const TextStyle(color: DD.textDim),
              ),
              const Spacer(),
              const Text('Total  ', style: TextStyle(color: DD.textDim)),
              AnimatedSwitcher(
                duration: DD.fast,
                child: Text(
                  euros(order.total),
                  key: ValueKey(order.total),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Pagas en la mesa al terminar', style: TextStyle(color: DD.textDim, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Enviar pedido a barra',
            trailing: 'Mesa ${order.table ?? '-'}',
            loading: _sending,
            onTap: _send,
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.order});
  final OrderLine line;
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DD.surface,
        borderRadius: BorderRadius.circular(DD.radius),
        border: Border.all(color: DD.line.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          ItemArt(item: line.item, size: const Size(48, 58)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  line.detail.isEmpty ? line.item.category.name : line.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DD.textDim, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(euros(line.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          QtyStepper(value: line.qty, min: 0, compact: true, onChanged: (v) => order.setQty(line, v)),
        ],
      ),
    );
  }
}
