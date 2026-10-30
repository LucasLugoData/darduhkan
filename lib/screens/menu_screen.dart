import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../state/order.dart';
import '../theme.dart';
import '../widgets/arch.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';
import 'item_screen.dart';
import 'welcome_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Category _category = categories.first;
  String _query = '';
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _select(Category c) {
    if (c == _category) return;
    setState(() => _category = c);
    if (_scroll.hasClients && _scroll.offset > 260) {
      _scroll.animateTo(260, duration: DD.medium, curve: DD.curve);
    }
  }

  List<MenuItem> get _results {
    final q = _norm(_query.trim());
    if (q.isEmpty) return itemsOf(_category);
    return menu
        .where((i) => _norm('${i.name} ${i.description} ${i.section} ${i.category.name}').contains(q))
        .toList();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 14) return 'Buenos días';
    if (h >= 14 && h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _openItem(MenuItem item, List<MenuItem> siblings) {
    Navigator.of(context).push(ItemScreen.route(siblings, siblings.indexOf(item)));
  }

  void _quickAdd(MenuItem item, List<MenuItem> siblings) {
    if (item.needsChoice) return _openItem(item, siblings);
    HapticFeedback.lightImpact();
    OrderScope.read(context).add(item);
    toast(context, '${item.name} añadido al pedido');
  }

  @override
  Widget build(BuildContext context) {
    final order = OrderScope.of(context);
    final items = _results;
    final searching = _query.trim().isNotEmpty;

    // Agrupa por sección conservando el orden de la carta.
    final sections = <String, List<MenuItem>>{};
    for (final i in items) {
      sections.putIfAbsent(searching ? i.category.name : i.section, () => []).add(i);
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _header(order)),
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _searchField()),
                SliverPersistentHeader(pinned: true, delegate: _ChipsHeader(_chips())),
                if (!searching) SliverToBoxAdapter(child: _banner()),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Nada por aquí con "$_query"', style: TextStyle(color: DD.textDim)),
                    ),
                  ),
                for (final entry in sections.entries) ...[
                  if (sections.length > 1 || searching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                        child: Text(entry.key, style: DD.script(size: 24, color: DD.silver)),
                      ),
                    ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final item = entry.value[i];
                      final siblings = searching ? items : itemsOf(item.category);
                      return FadeSlideIn(
                        key: ValueKey('${_category.id}-$_query-${item.id}'),
                        delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
                        child: _ItemRow(
                          item: item,
                          onTap: () => _openItem(item, siblings),
                          onAdd: () => _quickAdd(item, siblings),
                        ),
                      );
                    },
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          _CartBar(order: order),
        ],
      ),
    );
  }

  Widget _header(Order order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          ClipPath(
            clipper: const ArchClipper(),
            child: Container(
              width: 38,
              height: 46,
              color: DD.surfaceHi,
              alignment: const Alignment(0, 0.45),
              child: CustomPaint(
                size: const Size(13, 22),
                painter: HookahPainter(color: DD.silver),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAR DUKHAN', style: DD.brand(size: 14, spacing: 4)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context)
                          .pushReplacement(MaterialPageRoute<void>(builder: (_) => const WelcomeScreen())),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: DD.ember, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mesa ${order.table ?? '-'}',
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
            icon: Icons.notifications_none_rounded,
            tooltip: 'Llamar al camarero',
            onTap: () {
              HapticFeedback.mediumImpact();
              toast(
                context,
                'Hemos avisado a un camarero. Enseguida va a la mesa ${order.table}.',
                icon: Icons.room_service_outlined,
              );
            },
          ),
          const SizedBox(width: 10),
          const CartButton(),
        ],
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting(), style: const TextStyle(color: DD.textDim, fontSize: 15)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '¿Qué te apetece\n'),
                TextSpan(
                  text: 'esta noche?',
                  style: DD.script(size: 38, color: DD.ember),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Busca un sabor, una copa, una tapa…',
          hintStyle: const TextStyle(color: DD.textDim),
          prefixIcon: const Icon(Icons.search, color: DD.textDim),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: DD.textDim),
                  onPressed: () => setState(() {
                    _search.clear();
                    _query = '';
                  }),
                ),
          filled: true,
          fillColor: DD.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
          onTap: () {
            if (_query.isNotEmpty) {
              _search.clear();
              _query = '';
            }
            _select(c);
            setState(() {});
          },
        );
      },
    );
  }

  Widget _banner() {
    final c = _category;
    final sample = itemsOf(c).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: AnimatedSwitcher(
        duration: DD.medium,
        switchInCurve: DD.curve,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(c.id),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DD.radius + 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.tint.withValues(alpha: 0.22), DD.surface],
            ),
            border: Border.all(color: DD.line),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 22,
                bottom: 0,
                child: ItemArt(item: sample, size: const Size(104, 132), glow: 1.4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 140, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      c.bannerTitle,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(c.bannerText, style: const TextStyle(color: DD.textDim, fontSize: 13, height: 1.35)),
                    const SizedBox(height: 12),
                    Text(
                      '${itemsOf(c).length} opciones',
                      style: TextStyle(color: c.tint, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  _ChipsHeader(this.child);
  final Widget child;

  @override
  double get minExtent => 66;
  @override
  double get maxExtent => 66;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DD.bg.withValues(alpha: overlapsContent || shrinkOffset > 0 ? 0.96 : 1),
        border: Border(bottom: BorderSide(color: overlapsContent ? DD.line : Colors.transparent)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ChipsHeader old) => true;
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
            border: Border.all(color: DD.line.withValues(alpha: 0.6)),
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
                  child: const Icon(Icons.add, size: 20, color: DD.ember),
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
