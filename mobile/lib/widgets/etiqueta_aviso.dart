import 'package:flutter/material.dart';

import '../core/theme/colores_aviso.dart';
import '../models/publicacion_dto.dart';

/// Chip de color con ícono y texto para el tipo o el estado de un aviso.
class EtiquetaAviso extends StatelessWidget {
  EtiquetaAviso.tipo(int tipoPublicacion, {super.key})
    : estilo = ColoresAviso.tipo(tipoPublicacion),
      texto = etiquetasPublicacion[tipoPublicacion] ?? 'Aviso';
  const EtiquetaAviso.resuelta({super.key})
    : estilo = ColoresAviso.resuelta,
      texto = 'Resuelta';
  final EstiloAviso estilo;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
    decoration: BoxDecoration(
      color: estilo.fondo,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(estilo.icono, size: 14, color: estilo.color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: estilo.color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
