import 'package:flutter/material.dart';

/// Filas de [columnas] celdas del mismo ancho y, dentro de cada fila, la misma
/// altura. La última fila se completa con espacios para no estirar sus celdas.
class Grilla extends StatelessWidget {
  const Grilla({
    super.key,
    required this.columnas,
    required this.children,
    this.espacio = 8,
  });
  final int columnas;
  final List<Widget> children;
  final double espacio;

  @override
  Widget build(BuildContext context) => Column(
    spacing: espacio,
    children: [
      for (var i = 0; i < children.length; i += columnas)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: espacio,
            children: [
              for (var j = i; j < i + columnas; j++)
                Expanded(
                  child: j < children.length
                      ? children[j]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
    ],
  );
}
