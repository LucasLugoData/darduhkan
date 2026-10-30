import 'package:flutter/widgets.dart';

import '../data/models.dart';

class OrderLine {
  OrderLine({required this.item, this.variant, this.extras = const [], this.qty = 1});

  final MenuItem item;
  final String? variant;
  final List<Extra> extras;
  int qty;

  int get unitPrice => item.price + extras.fold(0, (s, e) => s + e.price);
  int get total => unitPrice * qty;

  String get key => '${item.id}|${variant ?? ''}|${extras.map((e) => e.name).join(',')}';

  String get detail => [?variant, ...extras.map((e) => '+ ${e.name}')].join(' · ');
}

class PlacedOrder {
  const PlacedOrder({required this.number, required this.table, required this.lines, required this.note});
  final String number;
  final int table;
  final List<OrderLine> lines;
  final String note;
  int get total => lines.fold(0, (s, l) => s + l.total);
}

/// Pedido en curso de la mesa. Sin backend: [submit] simula el envío a barra.
class Order extends ChangeNotifier {
  Order({this._table});

  int? _table;
  final List<OrderLine> _lines = [];
  String note = '';
  int _sent = 0;

  int? get table => _table;
  set table(int? v) {
    _table = v;
    notifyListeners();
  }

  List<OrderLine> get lines => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (s, l) => s + l.qty);
  int get total => _lines.fold(0, (s, l) => s + l.total);
  bool get isEmpty => _lines.isEmpty;

  void add(MenuItem item, {String? variant, List<Extra> extras = const [], int qty = 1}) {
    final line = OrderLine(item: item, variant: variant, extras: extras, qty: qty);
    final i = _lines.indexWhere((l) => l.key == line.key);
    if (i >= 0) {
      _lines[i].qty += qty;
    } else {
      _lines.add(line);
    }
    notifyListeners();
  }

  void setQty(OrderLine line, int qty) {
    if (qty <= 0) {
      _lines.remove(line);
    } else {
      line.qty = qty;
    }
    notifyListeners();
  }

  void remove(OrderLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  Future<PlacedOrder> submit() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _sent++;
    final placed = PlacedOrder(
      number: '${_table ?? 0}${_sent.toString().padLeft(2, '0')}',
      table: _table ?? 0,
      lines: List.of(_lines),
      note: note,
    );
    _lines.clear();
    note = '';
    notifyListeners();
    return placed;
  }
}

class OrderScope extends InheritedNotifier<Order> {
  const OrderScope({super.key, required Order order, required super.child}) : super(notifier: order);

  static Order of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrderScope>()!.notifier!;

  /// Acceso sin suscribirse a cambios (para callbacks).
  static Order read(BuildContext context) => context.getInheritedWidgetOfExactType<OrderScope>()!.notifier!;
}
