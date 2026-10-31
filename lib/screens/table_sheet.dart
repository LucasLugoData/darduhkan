import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../state/order.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'welcome_screen.dart';

/// La mesa: lo pedido en rondas anteriores, el total acumulado, llamar al
/// camarero y cambiar de mesa. Se abre tocando "Mesa N" en la carta.
Future<void> showTableSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DD.solid,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => const _TableSheet(),
);

class _TableSheet extends StatelessWidget {
  const _TableSheet();

  String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final order = OrderScope.of(context);
    final rounds = order.rounds;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: DD.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Mesa ${order.table ?? '-'}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (rounds.isNotEmpty)
                    Text(euros(order.tableTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                rounds.isEmpty
                    ? 'Aún no habéis pedido nada'
                    : '${rounds.length} ${rounds.length == 1 ? 'ronda pedida' : 'rondas pedidas'}',
                style: const TextStyle(color: DD.textDim, fontSize: 14),
              ),
              if (rounds.isNotEmpty) ...[
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final r in rounds.reversed) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Text(
                            'Ronda ${r.round} · ${_time(r.at)}',
                            style: const TextStyle(color: DD.textDim, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (final l in r.lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('${l.qty}×', style: const TextStyle(color: DD.textDim)),
                                ),
                                Expanded(
                                  child: Text(
                                    l.detail.isEmpty ? l.item.name : '${l.item.name} · ${l.detail}',
                                    style: const TextStyle(fontSize: 14.5),
                                  ),
                                ),
                                Text(euros(l.total), style: const TextStyle(color: DD.textDim)),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Llamar al camarero',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  toast(
                    context,
                    'Hemos avisado a un camarero. Enseguida va a la mesa ${order.table}.',
                    icon: Icons.room_service_outlined,
                  );
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context)
                  ..pop()
                  ..pushReplacement(MaterialPageRoute<void>(builder: (_) => const WelcomeScreen())),
                child: const Text('Cambiar de mesa', style: TextStyle(color: DD.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
