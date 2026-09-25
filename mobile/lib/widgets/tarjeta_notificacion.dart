import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../models/notificacion_dto.dart';
import '../models/publicacion_dto.dart';
import 'etiqueta_aviso.dart';

/// Posible coincidencia: la foto y el tipo del aviso que coincide, con cuál de
/// tus avisos. Las no leídas se destacan con fondo verde suave y un punto.
class TarjetaNotificacion extends StatelessWidget {
  const TarjetaNotificacion({
    super.key,
    required this.notificacion,
    required this.urlFoto,
    required this.onTap,
    required this.onVerMiAviso,
  });
  final NotificacionDto notificacion;
  final String Function(String path) urlFoto;
  final VoidCallback onTap, onVerMiAviso;

  Widget _miniatura(ThemeData theme) {
    final otra = notificacion.coincidente;
    final sinFoto = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
      child: Text(
        iconosMascota[otra.tipoMascota] ?? '🐾',
        style: const TextStyle(fontSize: 28),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: otra.fotoUrl == null
          ? sinFoto
          : Image.network(
              urlFoto(otra.fotoUrl!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => sinFoto,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notificacion;
    final otra = n.coincidente;
    final meta = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: n.leida ? Colors.white : ColoresApp.verdeSuave,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: n.leida
                ? theme.colorScheme.outlineVariant
                : ColoresApp.verde.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: n.leida ? null : 'No leída',
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniatura(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!n.leida)
                              Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.only(top: 6, right: 6),
                                decoration: const BoxDecoration(
                                  color: ColoresApp.verde,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                'Posible coincidencia con ${n.publicacion.titulo}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: n.leida
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            EtiquetaAviso.tipo(otra.tipoPublicacion),
                            if (otra.estado == 2)
                              const EtiquetaAviso.resuelta(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${iconosMascota[otra.tipoMascota] ?? ''} '
                          '${otra.titulo} · ${otra.localidad}',
                          style: meta,
                        ),
                        Text(
                          'Recibida ${fechaRelativa(n.fechaCreacion.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: onVerMiAviso,
                            child: Text(
                              'Ver mi aviso: ${n.publicacion.titulo}',
                            ),
                          ),
                        ),
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
