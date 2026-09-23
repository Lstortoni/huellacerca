import 'package:flutter/material.dart';

import 'grilla.dart';

class OpcionSelector {
  const OpcionSelector(this.id, this.texto, {this.adorno});
  final int id;
  final String texto;

  /// Elemento opcional antes del texto, por ejemplo un punto de color.
  final Widget? adorno;
}

/// Opciones en celdas del mismo tamaño (hasta 3 por fila). Admite quedar sin
/// selección: tocar la opción elegida la quita y avisa null.
class SelectorOpciones extends StatelessWidget {
  const SelectorOpciones({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onChanged,
    this.habilitado = true,
  });
  final List<OpcionSelector> opciones;
  final int? seleccion;
  final ValueChanged<int?> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Grilla(
      columnas: opciones.length < 3 ? opciones.length : 3,
      espacio: 6,
      children: [
        for (final o in opciones)
          Builder(
            builder: (context) {
              final elegida = seleccion == o.id;
              return Material(
                color: elegida ? scheme.primaryContainer : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: elegida ? scheme.primary : scheme.outlineVariant,
                    width: elegida ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Semantics(
                  button: true,
                  selected: elegida,
                  child: InkWell(
                    onTap: habilitado
                        ? () => onChanged(elegida ? null : o.id)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (o.adorno != null) ...[
                            o.adorno!,
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              o.texto,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: elegida
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: elegida
                                    ? scheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
