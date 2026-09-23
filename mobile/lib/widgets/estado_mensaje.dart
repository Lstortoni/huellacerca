import 'package:flutter/material.dart';

/// Mensaje centrado con ícono para resultados vacíos o errores, con una acción
/// opcional (por ejemplo, Reintentar).
class EstadoMensaje extends StatelessWidget {
  const EstadoMensaje({
    super.key,
    required this.icono,
    required this.mensaje,
    this.accion,
    this.onAccion,
  });
  final IconData icono;
  final String mensaje;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(icono, size: 30, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (accion != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAccion, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}
