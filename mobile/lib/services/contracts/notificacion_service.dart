import 'package:flutter/foundation.dart';

import '../../models/notificacion_dto.dart';
import '../../models/pagina_dto.dart';

/// Notificaciones internas de la cuenta. Es observable: la campanita escucha
/// [noLeidas] sin hacer llamadas HTTP por su cuenta.
abstract class NotificacionService implements Listenable {
  /// Cantidad de no leídas conocida; 0 sin sesión.
  int get noLeidas;

  /// Consulta el contador. Un fallo de red conserva el último valor.
  Future<void> actualizar();
  Future<PaginaDto<NotificacionDto>> listar({
    int pagina = 1,
    bool soloNoLeidas = false,
  });

  /// Baja el contador enseguida; si la API falla, se vuelve a consultar.
  Future<void> marcarLeida(NotificacionDto notificacion);
  Future<void> marcarTodas();

  /// La app en segundo plano no consulta; al volver, consulta enseguida.
  void pausar();
  void reanudar();
  void dispose();
}
