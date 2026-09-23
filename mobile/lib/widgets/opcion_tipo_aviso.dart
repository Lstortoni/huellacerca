import 'package:flutter/material.dart';

import '../core/theme/colores_aviso.dart';

/// Opción seleccionable con ícono. Horizontal para filtros; vertical (ícono
/// arriba) para formularios y grillas de 3 columnas.
class OpcionIcono extends StatelessWidget {
  const OpcionIcono({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
    required this.fondo,
    required this.seleccionado,
    required this.onTap,
    this.vertical = false,
  });
  final IconData icono;
  final String texto;
  final Color color, fondo;
  final bool seleccionado, vertical;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textoEstilo = theme.textTheme.labelLarge?.copyWith(
      fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
      color: seleccionado ? color : null,
    );
    return Material(
      color: seleccionado ? fondo : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(vertical ? 16 : 14),
        side: BorderSide(
          color: seleccionado ? color : theme.colorScheme.outlineVariant,
          width: seleccionado ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        selected: seleccionado,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: vertical
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: vertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, size: 28, color: color),
                      const SizedBox(height: 6),
                      Text(
                        texto,
                        textAlign: TextAlign.center,
                        style: textoEstilo,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, size: 20, color: color),
                      const SizedBox(width: 8),
                      Flexible(child: Text(texto, style: textoEstilo)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Opción de un tipo de aviso con su color e ícono.
class OpcionTipoAviso extends StatelessWidget {
  const OpcionTipoAviso({
    super.key,
    required this.tipo,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
    this.vertical = false,
  });
  final int tipo;
  final String texto;
  final bool seleccionado, vertical;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = ColoresAviso.tipo(tipo);
    return OpcionIcono(
      icono: estilo.icono,
      texto: texto,
      color: estilo.color,
      fondo: estilo.fondo,
      seleccionado: seleccionado,
      onTap: onTap,
      vertical: vertical,
    );
  }
}
