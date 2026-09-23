import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Ícono por nombre de rubro. Un rubro nuevo en la API usa el genérico.
IconData iconoRubro(String nombre) => switch (nombre.trim().toLowerCase()) {
  'veterinaria' => Icons.medical_services_rounded,
  'peluquería' || 'peluqueria' => Icons.content_cut_rounded,
  'paseador' => Icons.directions_walk_rounded,
  'cuidado y guardería' || 'cuidado y guarderia' => Icons.home_rounded,
  'tienda de mascotas' => Icons.shopping_bag_rounded,
  'otro' => Icons.more_horiz_rounded,
  _ => Icons.storefront_rounded,
};

/// Color de sección para Servicios: botones, selectores y título en ámbar.
class TemaServicios extends StatelessWidget {
  const TemaServicios({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: ColoresApp.ambar),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
            color: ColoresApp.ambar,
          ),
        ),
      ),
      child: child,
    );
  }
}
