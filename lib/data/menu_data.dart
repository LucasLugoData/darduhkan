import 'package:material_ui/material_ui.dart';

import 'models.dart';

// Carta de Dar Dukhan, transcrita de los PDF de la casa.

const shishas = Category(
  id: 'shishas',
  name: 'Shishas',
  icon: Icons.cloud_outlined,
  tint: Color(0xFFFF6A3D),
  art: ArtKind.hookah,
  bannerTitle: 'Shisha 15\u00A0€',
  bannerText: 'Elige tu sabor. Cabeza extra 5\u00A0€',
);
const comida = Category(
  id: 'comida',
  name: 'Comida',
  icon: Icons.lunch_dining_outlined,
  tint: Color(0xFFE9A23B),
  bannerTitle: 'Tapas y bocadillos',
  bannerText: 'Para compartir mientras fumas',
);
const cocteles = Category(
  id: 'cocteles',
  name: 'Cócteles',
  icon: Icons.local_bar_outlined,
  tint: Color(0xFFE5577A),
  bannerTitle: 'Cócteles de autor',
  bannerText: 'Con y sin alcohol. Batidos naturales 5\u00A0€',
);
const copas = Category(
  id: 'copas',
  name: 'Copas',
  icon: Icons.wine_bar_outlined,
  tint: Color(0xFFC79A5B),
  bannerTitle: 'Copas',
  bannerText: 'Suplemento Red Bull / Premium 1\u00A0€',
);
const cervezas = Category(
  id: 'cervezas',
  name: 'Cervezas',
  icon: Icons.sports_bar_outlined,
  tint: Color(0xFFF2C14E),
  bannerTitle: 'Cervezas y vino',
  bannerText: 'Siempre bien frías',
);
const bebidas = Category(
  id: 'bebidas',
  name: 'Bebidas',
  icon: Icons.emoji_food_beverage_outlined,
  tint: Color(0xFF4FB59B),
  bannerTitle: 'Té marroquí 3\u00A0€',
  bannerText: 'Cafés, infusiones y refrescos',
);
const botellas = Category(
  id: 'botellas',
  name: 'Botellas',
  icon: Icons.liquor_outlined,
  tint: Color(0xFFB9BCC6),
  bannerTitle: 'Botellas',
  bannerText: 'Para la mesa entera',
);

const categories = [shishas, comida, cocteles, copas, cervezas, bebidas, botellas];

const _extraHead = Extra('Cabeza extra', 500);
const _premium = Extra('Red Bull / Premium', 100);

MenuItem _i(
  Category c,
  String section,
  String name,
  int price, {
  IconData? icon,
  String desc = '',
  String tag = '',
  List<String> variants = const [],
  List<Extra> extras = const [],
}) => MenuItem(
  id: '${c.id}-${section.toLowerCase()}-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
  name: name,
  price: price,
  category: c,
  section: section,
  icon: icon ?? c.icon,
  description: desc,
  tag: tag,
  variants: variants,
  extras: extras,
);

MenuItem _shisha(String name, [String desc = '']) => _i(
  shishas,
  'Sabores',
  name,
  1500,
  desc: desc.isEmpty ? 'Sabor de la casa' : desc,
  tag: 'Shisha',
  extras: const [_extraHead],
);

MenuItem _food(
  String name,
  int price, {
  String desc = '',
  List<String> variants = const [],
  IconData? icon,
}) =>
    _i(comida, 'Tapas y bocadillos', name, price, desc: desc, tag: 'Cocina', variants: variants, icon: icon);

MenuItem _cocktail(String name, int price, String desc, {bool alcohol = true}) => _i(
  cocteles,
  alcohol ? 'Con alcohol' : 'Sin alcohol',
  name,
  price,
  desc: desc,
  tag: alcohol ? 'Con alcohol' : 'Sin alcohol',
  icon: alcohol ? Icons.local_bar_outlined : Icons.local_drink_outlined,
);

MenuItem _copa(String section, String name, int price) =>
    _i(copas, section, name, price, tag: section, extras: const [_premium], desc: 'Copa · $section');

MenuItem _beer(String name, int price, {String tag = 'Cerveza', IconData? icon}) =>
    _i(cervezas, 'Cervezas', name, price, tag: tag, icon: icon);

MenuItem _drink(
  String name,
  int price, {
  String desc = '',
  List<String> variants = const [],
  IconData? icon,
}) => _i(bebidas, 'Bebidas', name, price, desc: desc, tag: 'Sin alcohol', variants: variants, icon: icon);

MenuItem _bottle(String name, int price) =>
    _i(botellas, 'Botellas', name, price * 100, tag: 'Botella', desc: 'Botella para la mesa');

final List<MenuItem> menu = [
  // Shishas
  _shisha('Black Widow', 'Melón, mango y bayas con ligeras notas cremosas de nueces'),
  _shisha('Sueños Rojos', 'Frutos del bosque, piña y menta'),
  _shisha('Ambrosía', 'Melón, melocotón y menta'),
  _shisha('Mi Amor', 'Hielo, piña y plátano'),
  _shisha('Blueberry', 'Arándanos'),
  _shisha('Lady Killer', 'Melocotón, mango, menta y hielo'),
  _shisha('Mango Tanko Iss', 'Mango, maracuyá y hielo'),
  _shisha('Hawaii', 'Piña, mango y menta'),
  _shisha('Blu Iss', 'Arándanos y hielo'),
  _shisha('Vainilla Menta'),
  _shisha('Zeus'),
  _shisha('Aires de Verano'),
  _shisha('Swees Boom'),
  _shisha('Menta'),
  _shisha('Manzana'),
  _shisha('Sandía'),
  _shisha('Pera Menta'),
  _shisha('Sabores de la Casa', 'Pregunta por el sabor del día'),

  // Comida
  _food('Patatas Bravas', 500, icon: Icons.tapas_outlined),
  _food('Alitas', 450, icon: Icons.kebab_dining_outlined),
  _food(
    'Bocadillo de pinchos',
    700,
    variants: ['Pollo', 'Ternera', 'Salchichas'],
    icon: Icons.bakery_dining_outlined,
  ),
  _food('Hamburguesa', 650, variants: ['Ternera', 'Pollo']),
  _food('Hamburguesa Vegetal', 650),
  _food('Hamburguesa Champiñones', 650),
  _food('Plato combinado', 850, icon: Icons.dinner_dining_outlined),
  _food('Nuggets', 450, icon: Icons.fastfood_outlined),
  _food('Pimientos de Padrón', 300, icon: Icons.eco_outlined),
  _food('Bocadillo de Atún', 350, icon: Icons.bakery_dining_outlined),
  _food('Bocadillo Tortilla Francesa', 350, icon: Icons.bakery_dining_outlined),
  _food('Croquetas de Boletus', 650, icon: Icons.egg_outlined),
  _food('Croquetas de Pollo', 650, icon: Icons.egg_outlined),
  _food('Croquetas de Pulpo', 680, icon: Icons.egg_outlined),
  _food('Croquetas de Bacalao', 650, icon: Icons.egg_outlined),
  _food('Croquetas de Merluza, Camarones y Gambas', 690, icon: Icons.egg_outlined),
  _food('Brandada de Bacalao', 680, icon: Icons.set_meal_outlined),
  _food('Buñuelos de Bacalao', 650, icon: Icons.set_meal_outlined),
  _food('Delicias de Camembert', 680, icon: Icons.tapas_outlined),
  _food(
    'Tacos',
    780,
    variants: ['Pollo', 'Ternera', 'Salchichas', 'Atún', 'Cordon bleu'],
    icon: Icons.local_dining_outlined,
  ),
  _food('Tacos Tenders', 780, icon: Icons.local_dining_outlined),
  _food('Espinacas y Queso Azul', 670, icon: Icons.eco_outlined),
  _food('Fingers de Mozzarella', 650, icon: Icons.tapas_outlined),
  _food('Plato de Fruta', 450, icon: Icons.apple_outlined),
  _food('Tapa de Queso / Olivas', 350, variants: ['Queso', 'Olivas'], icon: Icons.tapas_outlined),
  _food(
    'Suplemento Patatas o Ensalada',
    250,
    variants: ['Patatas', 'Ensalada'],
    icon: Icons.add_circle_outline,
  ),

  // Cócteles con alcohol
  _cocktail('San Francisco', 900, 'Zumo de piña, naranja y melocotón, granadina y ron'),
  _cocktail('Mojito Menta', 900, 'Menta, lima, azúcar moreno y ron'),
  _cocktail('Mojito Fruta', 950, 'Fruta de temporada, lima, azúcar moreno, menta y ron'),
  _cocktail('Caipiriña', 900, 'Lima, azúcar moreno y cachaça'),
  _cocktail('Piña Colada', 900, 'Crema de coco, zumo de piña, Malibú y ron'),
  _cocktail('Margarita', 900, 'Sirope de azúcar, limón, tequila y Cointreau'),
  _cocktail('Pura Vida', 900, 'Limón, menta, piña, mango, Malibú y ron'),
  _cocktail('Coco Loco', 950, 'Crema de coco, limón, tequila blanco, ron y vodka'),
  _cocktail('Estarás en mi Corazón', 950, 'Frutos del bosque, granadina, limón, naranja y whisky'),
  _cocktail('Sex On The Beach', 900, 'Naranja, arándanos, licor de melocotón, Cointreau y vodka'),
  // Cócteles sin alcohol
  _cocktail('Mojito Menta', 700, 'Menta, lima y azúcar moreno', alcohol: false),
  _cocktail('Mojito Fresa', 800, 'Fresa, lima, azúcar moreno y menta', alcohol: false),
  _cocktail('Mojito Mango', 750, 'Mango, lima, azúcar moreno y menta', alcohol: false),
  _cocktail('Piña Colada', 750, 'Crema de coco, zumo de piña y azúcar líquido', alcohol: false),
  _cocktail('San Francisco', 750, 'Piña, melocotón, naranja y sirope de granadina', alcohol: false),
  _cocktail('Teide', 700, 'Plátano, fresa, mango y zumo de limón', alcohol: false),
  _cocktail('Primavera', 700, 'Frutos del bosque, naranja, piña, limón y granadina', alcohol: false),
  _cocktail('Kiwi Soda', 700, 'Kiwi, lima, soda, azúcar y hielo', alcohol: false),
  _cocktail('Troitis', 700, 'Sirope de melón, plátano, kiwi y piña', alcohol: false),
  _cocktail('Shangai', 700, 'Papaya, maracuyá, naranja y mango', alcohol: false),
  _i(
    cocteles,
    'Sin alcohol',
    'Batido de fruta natural',
    500,
    desc: 'Fruta natural batida al momento',
    tag: 'Sin alcohol',
    icon: Icons.blender_outlined,
  ),

  // Copas
  _copa('Whisky', 'J&B', 850),
  _copa('Whisky', "Ballantine's", 850),
  _copa('Whisky', 'J.W. Red', 850),
  _copa('Whisky', 'J.W. Black', 950),
  _copa('Whisky', 'J.W. Gold', 1100),
  _copa('Whisky', "Jack Daniel's", 950),
  _copa('Whisky', 'Four Roses', 850),
  _copa('Whisky', 'Chivas', 1100),
  _copa('Whisky', "Dewar's White Label", 850),
  _copa('Whisky', 'Cutty Sark', 850),
  _copa('Whisky', 'Thunder Bitch', 850),
  _copa('Ron', 'Bacardi', 850),
  _copa('Ron', 'Barceló', 950),
  _copa('Ron', 'Brugal', 950),
  _copa('Ron', 'Habana 7', 950),
  _copa('Ron', 'Habana 5', 850),
  _copa('Ron', 'Negrita', 800),
  _copa('Ron', 'Santa Teresa', 850),
  _copa('Ron', 'Cacique', 800),
  _copa('Ron', 'Cachaça', 800),
  _copa('Ron', 'Matusalem', 950),
  _copa('Ron', 'Malibú', 850),
  _copa('Ginebra', 'Beefeater', 850),
  _copa('Ginebra', 'Larios', 850),
  _copa('Ginebra', 'Tanqueray', 950),
  _copa('Ginebra', "Seagram's", 850),
  _copa('Ginebra', 'Bombay Sapphire', 1000),
  _copa('Ginebra', 'Bombay Dry Gin', 900),
  _copa('Ginebra', 'Bulldog', 1100),
  _copa('Ginebra', 'Puerto de Indias', 900),
  _copa('Vodka', 'Absolut', 850),
  _copa('Vodka', 'Eristoff Black', 850),
  _copa('Vodka', 'Smirnoff', 850),
  _copa('Vodka', 'Moskovskaya', 850),
  _copa('Vodka', 'Belvedere', 1100),
  _copa('Vodka', 'Winter Palace', 1100),
  _copa('Vodka', 'Grey Goose', 1100),
  _copa('Vodka', 'Cîroc', 1100),
  _copa('Varios', 'Martini', 850),
  _copa('Varios', 'Tequila', 850),
  _copa('Varios', 'Licor 43', 900),
  _copa('Varios', 'Jägermeister', 900),
  _copa('Varios', 'Baileys', 800),
  _copa('Varios', 'Anís', 750),
  _copa('Varios', 'Orujo de Hierbas', 750),
  _copa('Varios', 'Fireball', 750),

  // Cervezas
  _beer('Estrella Damm', 300),
  _beer('Voll-Damm', 350),
  _beer('Heineken', 350),
  _beer('Coronita', 400),
  _beer('Desperados', 400),
  _beer('Copa de Vino', 350, tag: 'Vino', icon: Icons.wine_bar_outlined),
  _beer('Free Damm', 300, tag: 'Sin alcohol'),
  _beer('Heineken 0,0', 300, tag: 'Sin alcohol'),
  _beer('Free Damm Limón', 300, tag: 'Sin alcohol'),

  // Bebidas
  _drink(
    'Té Marroquí',
    300,
    desc: 'Té verde con hierbabuena, servido a la manera tradicional',
    icon: Icons.emoji_food_beverage_outlined,
  ),
  _drink('Café con leche', 200, icon: Icons.local_cafe_outlined),
  _drink('Café americano', 150, icon: Icons.local_cafe_outlined),
  _drink('Café solo', 120, icon: Icons.coffee_outlined),
  _drink('Cortado', 130, icon: Icons.coffee_outlined),
  _drink('Carajillo', 250, icon: Icons.coffee_outlined),
  _drink('Poleo menta', 200, icon: Icons.spa_outlined),
  _drink('Manzanilla', 200, icon: Icons.spa_outlined),
  _drink('Refrescos', 400, icon: Icons.local_drink_outlined),
  _drink('Red Bull', 500, icon: Icons.bolt_outlined),
  _drink(
    'Zumos',
    400,
    variants: ['Melocotón', 'Piña', 'Naranja', 'Manzana'],
    icon: Icons.local_drink_outlined,
  ),
  _drink('Hawaii', 400, icon: Icons.local_drink_outlined),
  _drink('Poms', 400, icon: Icons.local_drink_outlined),
  _drink('Vichy Catalán', 400, icon: Icons.water_drop_outlined),
  _drink('Ginger Ale', 400, icon: Icons.local_drink_outlined),

  // Botellas
  _bottle('Belvedere', 150),
  _bottle('Grey Goose', 150),
  _bottle('J.W. Gold', 150),
  _bottle('Puerto de Indias', 100),
  _bottle('J.W. Black', 100),
  _bottle("Jack Daniel's", 100),
  _bottle('Chivas', 100),
  _bottle('Matusalem', 100),
  _bottle('Bombay Sapphire', 100),
  _bottle('Bulldog', 100),
  _bottle('Absolut', 90),
  _bottle('J&B', 90),
  _bottle("Ballantine's", 90),
  _bottle('J.W. Red', 90),
  _bottle('Four Roses', 90),
  _bottle('Beefeater', 90),
  _bottle("Seagram's", 90),
  _bottle('Barceló', 90),
  _bottle('Brugal', 90),
  _bottle('Habana 7', 90),
  _bottle('Negrita', 90),
  _bottle('Santa Teresa', 90),
  _bottle('Cacique', 90),
  _bottle('Tequila', 90),
  _bottle('Licor 43', 90),
  _bottle('Jägermeister', 90),
  _bottle('Moët Ice', 90),
  _bottle('Botella de Vino', 15),
];

List<MenuItem> itemsOf(Category c) => menu.where((i) => i.category == c).toList();
