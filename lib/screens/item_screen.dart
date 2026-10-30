import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';

/// Ficha de producto con carrusel deslizable entre los productos de la categoría,
/// al estilo de la referencia del café: el central crece, los laterales asoman.
class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key, required this.items, required this.initial});
  final List<MenuItem> items;
  final int initial;

  static Route<void> route(List<MenuItem> items, int initial) => PageRouteBuilder(
    transitionDuration: DD.medium,
    reverseTransitionDuration: DD.medium,
    pageBuilder: (_, _, _) => ItemScreen(items: items, initial: initial),
    transitionsBuilder: (_, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: DD.curve),
      child: child,
    ),
  );

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  late final _pages = PageController(viewportFraction: 0.56, initialPage: widget.initial);
  late int _index = widget.initial;
  String? _variant;
  final Set<Extra> _extras = {};
  int _qty = 1;

  MenuItem get _item => widget.items[_index];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPage(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _variant = null;
      _extras.clear();
      _qty = 1;
    });
  }

  int get _unit => _item.price + _extras.fold(0, (s, e) => s + e.price);

  void _add() {
    final item = _item;
    if (item.needsChoice && _variant == null) {
      HapticFeedback.heavyImpact();
      toast(context, 'Elige una opción para ${item.name}', icon: Icons.touch_app_outlined);
      return;
    }
    HapticFeedback.mediumImpact();
    OrderScope.read(context).add(item, variant: _variant, extras: _extras.toList(), qty: _qty);
    toast(context, '$_qty × ${item.name} añadido al pedido');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  RoundIconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(
                      item.category.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: DD.brand(size: 13, spacing: 5),
                    ),
                  ),
                  const CartButton(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _infoCards(item),
                    const SizedBox(height: 18),
                    _carousel(),
                    const SizedBox(height: 8),
                    _dots(),
                    const SizedBox(height: 18),
                    _titleBlock(item),
                    _options(item),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _infoCards(MenuItem item) {
    final facts = [
      (Icons.grid_view_rounded, 'Sección', item.section),
      (item.category.icon, 'Tipo', item.tag.isEmpty ? item.category.name : item.tag),
      (Icons.sell_outlined, 'Precio', euros(item.price)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (i, f) in facts.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                decoration: BoxDecoration(
                  color: DD.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DD.line.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(f.$1, size: 18, color: DD.textDim),
                    const SizedBox(height: 12),
                    Text(f.$2, style: const TextStyle(color: DD.textDim, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: DD.fast,
                      child: Text(
                        f.$3,
                        key: ValueKey(f.$3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _carousel() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pages,
        itemCount: widget.items.length,
        onPageChanged: _onPage,
        itemBuilder: (_, i) {
          final it = widget.items[i];
          return AnimatedBuilder(
            animation: _pages,
            builder: (_, child) {
              final page = _pages.hasClients && _pages.position.haveDimensions
                  ? _pages.page!
                  : widget.initial.toDouble();
              final d = (page - i).clamp(-1.0, 1.0);
              final t = d.abs();
              return Opacity(
                opacity: 1 - t * 0.55,
                child: Transform.translate(
                  offset: Offset(d * 24, t * 34),
                  child: Transform.scale(scale: 1 - t * 0.32, child: child),
                ),
              );
            },
            child: GestureDetector(
              onTap: () => _pages.animateToPage(i, duration: DD.medium, curve: DD.curve),
              child: Center(
                child: Hero(
                  tag: 'art-${it.id}',
                  child: ItemArt(item: it, size: const Size(184, 240), glow: 1.25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dots() {
    final n = widget.items.length;
    // Con muchas opciones, una barra de progreso fina en vez de puntos.
    return SizedBox(
      width: 120,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(color: DD.line),
            AnimatedFractionallySizedBox(
              duration: DD.medium,
              curve: DD.curve,
              widthFactor: 1 / n,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * _index / (n - 1), 0),
              child: Container(color: DD.ember),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock(MenuItem item) {
    return AnimatedSwitcher(
      duration: DD.medium,
      switchInCurve: DD.curve,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
          child: c,
        ),
      ),
      child: Padding(
        key: ValueKey(item.id),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DD.textDim, fontSize: 14.5, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _options(MenuItem item) {
    return AnimatedSize(
      duration: DD.medium,
      curve: DD.curve,
      alignment: Alignment.topCenter,
      child: Column(
        key: ValueKey('opts-${item.id}'),
        children: [
          if (item.variants.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Elige una opción', style: DD.script(size: 20, color: DD.silver)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in item.variants)
                  Pill(label: v, selected: _variant == v, onTap: () => setState(() => _variant = v)),
              ],
            ),
          ],
          if (item.extras.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Extras', style: DD.script(size: 20, color: DD.silver)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
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
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DD.line)),
      ),
      child: Row(
        children: [
          QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(label: 'Añadir', trailing: euros(_unit * _qty), onTap: _add),
          ),
        ],
      ),
    );
  }
}
