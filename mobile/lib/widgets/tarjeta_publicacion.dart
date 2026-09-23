import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/publicacion_service.dart';
import 'etiqueta_aviso.dart';
import 'foto_publicacion.dart';

/// Tarjeta de un aviso para búsqueda, Mis publicaciones y coincidencias.
/// Los avisos resueltos se ven atenuados.
class TarjetaPublicacion extends StatelessWidget {
  const TarjetaPublicacion({
    super.key,
    required this.publicacion,
    required this.service,
    required this.onTap,
    this.detalle,
  });
  final PublicacionDto publicacion;
  final PublicacionService service;
  final VoidCallback onTap;

  /// Texto adicional debajo de los datos, por ejemplo "Coincide en: …".
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = publicacion;
    final resuelta = p.estado == 2;
    final meta = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget dato(IconData icono, String texto) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icono, size: 16, color: theme.colorScheme.outline),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(texto, style: meta)),
      ],
    );
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
          child: Opacity(
            opacity: resuelta ? 0.6 : 1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiniaturaPublicacion(
                    publicacion: p,
                    service: service,
                    lado: 80,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            EtiquetaAviso.tipo(p.tipoPublicacion),
                            if (resuelta) const EtiquetaAviso.resuelta(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        dato(
                          Icons.location_on_rounded,
                          '${p.localidad}, ${p.provincia}',
                        ),
                        dato(Icons.event_rounded, p.resumenFecha),
                        if (detalle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            detalle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
