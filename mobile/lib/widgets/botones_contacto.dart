import 'package:flutter/material.dart';

/// Llamar y WhatsApp lado a lado, del mismo tamaño. Si no hay una app que
/// pueda abrir la acción, lo informa con un aviso.
class BotonesContacto extends StatelessWidget {
  const BotonesContacto({
    super.key,
    required this.llamar,
    required this.whatsapp,
  });
  final Future<bool> Function() llamar, whatsapp;

  Future<void> _abrir(
    BuildContext context,
    Future<bool> Function() accion,
    String sinApp,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await accion()) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(sinApp)));
  }

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      Expanded(
        child: FilledButton.tonalIcon(
          onPressed: () => _abrir(
            context,
            llamar,
            'No encontramos una app para llamar. Copiá el número.',
          ),
          icon: const Icon(Icons.call_rounded),
          label: const Text('Llamar'),
        ),
      ),
      Expanded(
        child: FilledButton.tonalIcon(
          onPressed: () => _abrir(
            context,
            whatsapp,
            'No pudimos abrir WhatsApp. Copiá el número.',
          ),
          icon: const Icon(Icons.chat_rounded),
          label: const Text('WhatsApp'),
        ),
      ),
    ],
  );
}
