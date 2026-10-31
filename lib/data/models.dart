import 'package:material_ui/material_ui.dart';

enum ArtKind { hookah, icon }

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.tint,
    required this.bannerTitle,
    required this.bannerText,
    this.art = ArtKind.icon,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color tint;
  final String bannerTitle;
  final String bannerText;
  final ArtKind art;
}

class Extra {
  const Extra(this.name, this.price);
  final String name;
  final int price;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.section,
    required this.icon,
    this.description = '',
    this.tag = '',
    this.variants = const [],
    this.extras = const [],
    this.combo = false,
    required this.imageKey,
  });

  final String id;
  final String name;

  /// Precio en céntimos.
  final int price;
  final Category category;
  final String section;
  final IconData icon;
  final String description;

  /// Etiqueta corta mostrada en las tarjetas de información (p. ej. "Sin alcohol").
  final String tag;
  final List<String> variants;
  final List<Extra> extras;

  /// Se puede pedir solo o en menú (acompañamiento + bebida).
  final bool combo;

  /// Clave de la foto en `assets/products/<imageKey>.webp`. Varios productos
  /// pueden compartirla (p. ej. todas las copas de whisky).
  final String imageKey;

  bool get needsChoice => variants.isNotEmpty;
}
