import 'package:flutter/material.dart';

import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';

/// Destino temporal de las tarjetas. No simula consultas ni publicaciones.
class FuncionPendientePage extends StatelessWidget {
  const FuncionPendientePage({
    super.key,
    required this.auth,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.requiereSesion = false,
  });
  final AuthService auth;
  final String titulo, descripcion;
  final IconData icono;
  final bool requiereSesion;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: auth, titulo: titulo),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final ingresar = requiereSesion && !auth.autenticado;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icono,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Próximamente',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(descripcion, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta función todavía no está disponible.',
                      textAlign: TextAlign.center,
                    ),
                    if (ingresar) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Para participar vas a necesitar una cuenta.',
                        textAlign: TextAlign.center,
                      ),
                      FilledButton(
                        onPressed: auth.restaurando
                            ? null
                            : () => Navigator.of(context).pushNamed('/login'),
                        child: const Text('Ingresar'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
