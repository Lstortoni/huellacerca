import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../core/theme/tema_servicios.dart';
import '../models/recomendacion_dto.dart';

/// Insignia ámbar con la cantidad de personas que recomiendan.
class InsigniaVotos extends StatelessWidget {
  const InsigniaVotos({super.key, required this.cantidad});
  final int cantidad;

  @override
  Widget build(BuildContext context) => Semantics(
    label: cantidad == 1
        ? '1 persona lo recomienda'
        : '$cantidad personas lo recomiendan',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ColoresApp.ambarSuave,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thumb_up_rounded, size: 15, color: ColoresApp.ambar),
          const SizedBox(width: 4),
          Text(
            '$cantidad',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ColoresApp.ambar,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Círculo ámbar con el ícono del rubro.
class IconoRubro extends StatelessWidget {
  const IconoRubro({
    super.key,
    required this.rubro,
    this.lado = 48,
    this.solido = false,
  });
  final String rubro;
  final double lado;
  final bool solido;

  @override
  Widget build(BuildContext context) => Container(
    width: lado,
    height: lado,
    decoration: BoxDecoration(
      color: solido ? ColoresApp.ambar : ColoresApp.ambarSuave,
      borderRadius: BorderRadius.circular(lado / 3),
    ),
    child: Icon(
      iconoRubro(rubro),
      size: lado * 0.5,
      color: solido ? Colors.white : ColoresApp.ambar,
    ),
  );
}

/// Tarjeta de un prestador: rubro, votos y los aspectos más destacados.
/// [pie] permite agregar acciones, por ejemplo recomendar desde similares.
class TarjetaPrestador extends StatelessWidget {
  const TarjetaPrestador({
    super.key,
    required this.prestador,
    this.onTap,
    this.pie,
  });
  final PrestadorDto prestador;
  final VoidCallback? onTap;
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = prestador;
    final destacados = [...p.aspectos.where((a) => a.cantidad > 0)]
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconoRubro(rubro: p.rubro),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${p.rubro} · ${p.localidad}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InsigniaVotos(cantidad: p.totalRecomendaciones),
                  ],
                ),
                if (destacados.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in destacados.take(3))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '${a.nombre} ${a.cantidad}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                    ],
                  ),
                ],
                if (pie != null) ...[const SizedBox(height: 10), pie!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
