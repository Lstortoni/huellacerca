import 'package:flutter/material.dart';

/// Color fuerte (ícono/texto), fondo suave e ícono de un tipo o estado de aviso.
class EstiloAviso {
  const EstiloAviso(this.color, this.fondo, this.icono);
  final Color color, fondo;
  final IconData icono;
}

/// Colores con significado: son iguales en toda la app, independientes de la
/// sección. Siempre se muestran junto a un ícono y un texto.
abstract final class ColoresAviso {
  static const _tipos = {
    1: EstiloAviso(Color(0xFFB23A24), Color(0xFFFBE3DC), Icons.search_rounded),
    2: EstiloAviso(
      Color(0xFF1F5E9E),
      Color(0xFFDFEBF8),
      Icons.where_to_vote_rounded,
    ),
    3: EstiloAviso(
      Color(0xFF6D43A6),
      Color(0xFFEEE4F8),
      Icons.volunteer_activism_rounded,
    ),
    4: EstiloAviso(Color(0xFF8E5A07), Color(0xFFFAEDD2), Icons.house_rounded),
  };
  static const resuelta = EstiloAviso(
    Color(0xFF4F5853),
    Color(0xFFE6E9E6),
    Icons.check_circle_rounded,
  );
  static EstiloAviso tipo(int tipoPublicacion) =>
      _tipos[tipoPublicacion] ?? resuelta;
}
