import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';
import '../widgets/smoke.dart';
import 'cart_screen.dart';
import 'item_sheet.dart';
import 'table_sheet.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Category _category = categories.first;
  String _query = '';
  bool _searching = false;
  bool _list = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MenuItem> get _results {
    final q = _norm(_query.trim());
    if (q.isEmpty) return itemsOf(_category);
    return menu
        .where((i) => _norm('${i.name} ${i.description} ${i.section} ${i.category.name}').contains(q))
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search.clear();
        _query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = OrderScope.of(context);
    final items = _results;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Hueco para la barra del pedido y la barra de navegación del sistema.
    final reserve = (order.count > 0 ? 96.0 : 16.0) + bottomInset;

    return Scaffold(
      body: Smoke(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(order),
                  AnimatedSize(
                    duration: DD.medium,
                    curve: DD.curve,
                    child: _searching ? _searchField() : const SizedBox(width: double.infinity),
                  ),
                  SizedBox(height: 64, child: _chips()),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text('Nada por aquí con "$_query"', style: const TextStyle(color: DD.textDim)),
                          )
                        : AnimatedSwitcher(
                            duration: DD.medium,
                            switchInCurve: DD.curve,
                            child: KeyedSubtree(
                              key: ValueKey('${_category.id}|$_query|$_list'),
                              child: _list
                                  ? _listView(items, reserve)
                                  : _CarouselView(
                                      items: items,
                                      bottom: reserve,
                                      onOpen: (i) => addToOrder(context, i, ask: true),
                                      onAdd: (i) => addToOrder(context, i),
                                    ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Difumina lo que pasa por debajo de la barra del pedido y de la del sistema.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: reserve + 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [DD.bg.withValues(alpha: 0), DD.bg.withValues(alpha: 0.92), DD.bg],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            _CartBar(order: order),
          ],
        ),
      ),
    );
  }

  Widget _listView(List<MenuItem> items, double bottom) => ListView.builder(
    padding: EdgeInsets.only(top: 4, bottom: bottom),
    itemCount: items.length,
    itemBuilder: (_, i) => FadeSlideIn(
      delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
      child: _ItemRow(
        item: items[i],
        onTap: () => addToOrder(context, items[i], ask: true),
        onAdd: () => addToOrder(context, items[i]),
      ),
    ),
  );

  Widget _header(Order order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAR DUKHAN', style: DD.brand(size: 14, spacing: 4)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => showTableSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: DD.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mesa ${order.table ?? '-'}'
                        '${order.rounds.isEmpty ? '' : ' · ${order.rounds.length} ${order.rounds.length == 1 ? 'ronda' : 'rondas'}'}',
                        style: const TextStyle(color: DD.textDim, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.expand_more, size: 16, color: DD.textDim),
                    ],
                  ),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: _searching ? Icons.close : Icons.search,
            tooltip: 'Buscar',
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: _list ? Icons.view_carousel_outlined : Icons.view_agenda_outlined,
            tooltip: _list ? 'Ver de una en una' : 'Ver en lista',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _list = !_list);
            },
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: TextField(
        controller: _search,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Busca un sabor, una copa, una tapa…',
          hintStyle: const TextStyle(color: DD.textDim),
          prefixIcon: const Icon(Icons.search, color: DD.textDim),
          filled: true,
          fillColor: DD.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _chips() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final c = categories[i];
        return Pill(
          label: c.name,
          icon: c.icon,
          selected: c == _category && _query.isEmpty,
          onTap: () => setState(() {
            _search.clear();
            _query = '';
            _searching = false;
            _category = c;
          }),
        );
      },
    );
  }
}

/// Carta de una en una: se pasa deslizando; la central crece y las laterales asoman.
class _CarouselView extends StatefulWidget {
  const _CarouselView({required this.items, required this.bottom, required this.onOpen, required this.onAdd});
  final List<MenuItem> items;
  final double bottom;
  final ValueChanged<MenuItem> onOpen;
  final ValueChanged<MenuItem> onAdd;

  @override
  State<_CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<_CarouselView> {
  final _pages = PageController(viewportFraction: 0.74);
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final n = widget.items.length;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottom),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) {
                final h = c.maxHeight - 16;
                final w = (c.maxWidth * 0.74 - 24).clamp(0.0, h / 1.3);
                return PageView.builder(
                  controller: _pages,
                  itemCount: n,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (_, i) => AnimatedBuilder(
                    animation: _pages,
                    builder: (_, child) {
                      final page = _pages.hasClients && _pages.position.haveDimensions ? _pages.page! : 0.0;
                      final t = (page - i).abs().clamp(0.0, 1.0);
                      return Opacity(
                        opacity: 1 - t * 0.6,
                        child: Transform.scale(scale: 1 - t * 0.22, child: child),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => widget.onOpen(widget.items[i]),
                      child: Center(
                        child: ItemArt(item: widget.items[i], size: Size(w, w * 1.3), glow: 1.25),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: DD.medium,
            switchInCurve: DD.curve,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(a),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 38,
                    child: Text(
                      item.description.isNotEmpty ? item.description : item.variants.join(' · '),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: DD.textDim, fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('${_index + 1} / $n', style: const TextStyle(color: DD.textDim, fontSize: 13)),
                const Spacer(),
                Text(euros(item.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(width: 12),
                Pressable(
                  onTap: () => widget.onAdd(item),
                  scale: 0.9,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: DD.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: DD.bg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String _norm(String s) {
  const from = 'áéíóúüñàèìòùâêîôûäëïöç';
  const to = 'aeiouunaeiouaeiouaeioc';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap, required this.onAdd});
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.description.isNotEmpty
        ? item.description
        : item.variants.isNotEmpty
        ? item.variants.join(' · ')
        : '';
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DD.surface,
            borderRadius: BorderRadius.circular(DD.radius),
            border: Border.all(color: DD.line),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'art-${item.id}',
                child: ItemArt(item: item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: DD.textDim, fontSize: 12.5, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      euros(item.price),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: onAdd,
                scale: 0.85,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DD.surfaceHi,
                    shape: BoxShape.circle,
                    border: Border.all(color: DD.line),
                  ),
                  child: const Icon(Icons.add, size: 20, color: DD.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final visible = order.count > 0;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.6),
          duration: DD.medium,
          curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: DD.fast,
            child: PrimaryButton(
              label: 'Ver pedido · ${order.count} ${order.count == 1 ? 'artículo' : 'artículos'}',
              trailing: euros(order.total),
              onTap: visible ? () => Navigator.of(context).push(CartScreen.route()) : null,
            ),
          ),
        ),
      ),
    );
  }
}
