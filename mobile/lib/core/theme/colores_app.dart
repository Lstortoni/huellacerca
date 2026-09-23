import 'package:flutter/material.dart';

/// Colores de marca y de acento compartidos por las pantallas.
/// Cada acento tiene un tono fuerte (ícono/texto) y uno suave (fondo).
abstract final class ColoresApp {
  static const fondo = Color(0xFFF6F5F0);
  static const verde = Color(0xFF246653);
  static const verdeClaro = Color(0xFF2F7F68);
  static const verdeSuave = Color(0xFFDDEEE6);
  static const ambar = Color(0xFF9A6200);
  static const ambarBoton = Color(0xFFF0B44C);
  static const ambarTexto = Color(0xFF3A2600);
  static const ambarSuave = Color(0xFFFBEBCB);
  static const azul = Color(0xFF1F5E9E);
  static const azulSuave = Color(0xFFDFEBF8);
  static const violeta = Color(0xFF6D43A6);
  static const violetaSuave = Color(0xFFEEE4F8);

  /// Ámbar = acción principal: el botón que inicia una tarea y el que la termina.
  static const accionPrincipal = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(ambarBoton),
    foregroundColor: WidgetStatePropertyAll(ambarTexto),
    minimumSize: WidgetStatePropertyAll(Size(0, 52)),
  );

  /// Muestra de color por id de ColorPredominante de la API (7 = Mixto/Otro).
  static const pelaje = {
    1: Color(0xFF222222),
    2: Color(0xFFFFFFFF),
    3: Color(0xFF7B4A2A),
    4: Color(0xFF9A9A9A),
    5: Color(0xFFE3C99A),
    6: Color(0xFFE08A2E),
  };
}
