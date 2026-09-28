import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Diagnóstico temporal para probar Firebase desde su consola, sin nuestra API.
Future<void> prepararPruebaPush() async {
  if (!kDebugMode ||
      kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  try {
    final messaging = FirebaseMessaging.instance;
    final permisos = await messaging.requestPermission();
    debugPrint('[Push prueba] Permiso: ${permisos.authorizationStatus.name}');

    if (permisos.authorizationStatus != AuthorizationStatus.authorized &&
        permisos.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint(
        '[Push prueba] Notificaciones sin permiso. Podés habilitarlas en '
        'Ajustes de Android > Aplicaciones > Huella Cerca > Notificaciones '
        'y volver a ejecutar la app.',
      );
      return;
    }

    final token = await messaging.getToken().timeout(
      const Duration(seconds: 20),
    );
    if (token == null || token.isEmpty) {
      debugPrint('[Push prueba] Firebase todavía no devolvió un token.');
      return;
    }

    // Solo en debug: copiar este valor para el envío de prueba desde Firebase.
    debugPrint('[Push prueba] Token FCM: $token');
  } on TimeoutException {
    debugPrint(
      '[Push prueba] No se obtuvo el token en 20 segundos. Revisá la conexión '
      'del emulador y volvé a ejecutar la app.',
    );
  } on FirebaseException catch (e) {
    debugPrint('[Push prueba] Error Firebase (${e.code}): ${e.message}');
  } catch (e) {
    // Una falla de esta prueba no impide utilizar el resto de la app.
    debugPrint('[Push prueba] No se pudo preparar la prueba: $e');
  }
}
