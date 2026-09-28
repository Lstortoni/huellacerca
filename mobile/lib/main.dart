import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_registration.dart';
import 'core/notifications/prueba_push.dart';

// Punto de entrada. La configuración visual vive en app.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Por ahora Firebase está configurado únicamente para Android.
  // Usa la configuración de android/app/google-services.json.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }

  configurarServicios();
  runApp(const HuellaCercaApp());

  // Prueba manual: pedir permiso cuando la primera pantalla ya está visible.
  if (kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await prepararPruebaPush();
    });
  }
}
