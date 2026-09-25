import 'package:flutter/widgets.dart';

import '../services/contracts/notificacion_service.dart';

/// Publica el contrato de notificaciones una sola vez en app.dart, para que la
/// barra lo use sin recibirlo por constructor en cada página. Sus dependientes
/// se reconstruyen cuando cambia el contador.
class NotificacionesScope extends InheritedNotifier<NotificacionService> {
  const NotificacionesScope({
    super.key,
    required NotificacionService super.notifier,
    required super.child,
  });

  /// null si la app no lo configuró (por ejemplo, en pruebas de una página).
  static NotificacionService? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NotificacionesScope>()
      ?.notifier;
}
