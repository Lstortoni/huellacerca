import 'package:flutter/material.dart';

/// Acceso reutilizable: muestra una acción y avisa cuando la persona la toca.
class TarjetaInicio extends StatelessWidget {
  const TarjetaInicio({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.onTap,
  });
  final String titulo, descripcion;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      icono,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(descripcion, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
