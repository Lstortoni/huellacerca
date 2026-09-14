import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_registration.dart';

// Punto de entrada. La configuración visual vive en app.dart.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configurarServicios();
  runApp(const HuellaCercaApp());
}
