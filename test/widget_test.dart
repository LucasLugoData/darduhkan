import 'dart:convert';
import 'dart:io';

import 'package:dar_dukhan/data/menu_data.dart';
import 'package:dar_dukhan/data/product_images.g.dart';
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

  test('el mismo plato solo y en menú son líneas distintas y el menú suma su precio', () {
    final order = Order(table: 2);
    final nuggets = itemsOf(comida).firstWhere((i) => i.name == 'Nuggets');
    expect(nuggets.combo, isTrue);
    order.add(nuggets);
    order.add(nuggets, combo: ['Patatas', 'Red Bull'], comboPrice: comboPrice + 100);
    expect(order.lines.length, 2);
    expect(order.lines.last.detail, 'Menú: Patatas + Red Bull');
    expect(order.total, 450 * 2 + comboPrice + 100);
  });

  test('enviar el pedido vacía el carrito', () async {
    final order = Order(table: 7)..add(itemsOf(bebidas).first, qty: 2);
    final placed = await order.submit();
    expect(placed.table, 7);
    expect(placed.total, 600);
    expect(order.isEmpty, isTrue);
  });

  test('la mesa guarda las rondas anteriores y su total', () async {
    final order = Order(table: 3)..add(itemsOf(bebidas).first);
    await order.submit();
    order.add(itemsOf(shishas).first);
    final second = await order.submit();
    expect(second.round, 2);
    expect(order.rounds.length, 2);
    expect(order.tableTotal, itemsOf(bebidas).first.price + 1500);
    order.table = 4;
    expect(order.rounds, isEmpty);
  });

  test('cada categoría tiene productos y los ids son únicos', () {
    for (final c in categories) {
      expect(itemsOf(c), isNotEmpty);
    }
    expect(menu.map((i) => i.id).toSet().length, menu.length);
  });

  test('cada foto de producto tiene prompt y las del índice existen', () {
    final prompts = jsonDecode(File('tool/image_prompts.json').readAsStringSync()) as Map<String, dynamic>;
    final keys = menu.map((i) => i.imageKey).toSet();
    expect(keys.difference(prompts.keys.toSet()), isEmpty);
    for (final k in productImages) {
      expect(File('assets/products/$k.webp').existsSync(), isTrue, reason: k);
    }
  });
}
