import 'package:dar_dukhan/data/menu_data.dart';
import 'package:dar_dukhan/state/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las líneas iguales se agrupan y los extras suman al precio', () {
    final order = Order(table: 4);
    final shisha = itemsOf(shishas).first;
    order.add(shisha);
    order.add(shisha);
    order.add(shisha, extras: shisha.extras);
    expect(order.lines.length, 2);
    expect(order.count, 3);
    expect(order.total, 1500 * 3 + 500);
  });

  test('enviar el pedido vacía el carrito', () async {
    final order = Order(table: 7)..add(itemsOf(bebidas).first, qty: 2);
    final placed = await order.submit();
    expect(placed.table, 7);
    expect(placed.total, 600);
    expect(order.isEmpty, isTrue);
  });

  test('cada categoría tiene productos y los ids son únicos', () {
    for (final c in categories) {
      expect(itemsOf(c), isNotEmpty);
    }
    expect(menu.map((i) => i.id).toSet().length, menu.length);
  });
}
