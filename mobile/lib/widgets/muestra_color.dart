import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';

/// Punto con el color predominante de la API (id 7 = Mixto/Otro, multicolor).
class MuestraColor extends StatelessWidget {
  const MuestraColor({super.key, required this.id, this.lado = 14});
  final int id;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final color = ColoresApp.pelaje[id];
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: color == null
            ? const SweepGradient(
                colors: [
                  Color(0xFF7B4A2A),
                  Color(0xFFE08A2E),
                  Color(0xFF222222),
                  Color(0xFFE3C99A),
                  Color(0xFF7B4A2A),
                ],
              )
            : null,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
