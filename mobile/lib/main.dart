import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_registration.dart';

// Punto de entrada. La configuración visual vive en app.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Por ahora Firebase está configurado únicamente para Android.
  // Usa la configuración de android/app/google-services.json.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }

  configurarServicios(
    habilitarPush: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  );
  runApp(const HuellaCercaApp());
}
