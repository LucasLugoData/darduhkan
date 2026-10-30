import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_screen.dart';
import 'state/order.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DD.bg,
    ),
  );
  runApp(DarDukhanApp(order: Order(table: _tableFromUrl())));
}

/// En web, un QR por mesa puede abrir la app con `?mesa=7` y saltarse la selección.
int? _tableFromUrl() => kIsWeb ? int.tryParse(Uri.base.queryParameters['mesa'] ?? '') : null;

class DarDukhanApp extends StatelessWidget {
  const DarDukhanApp({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return OrderScope(
      order: order,
      child: MaterialApp(
        title: 'Dar Dukhan',
        debugShowCheckedModeBanner: false,
        theme: DD.theme(),
        // Permite arrastrar carruseles también con ratón (web / escritorio).
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
