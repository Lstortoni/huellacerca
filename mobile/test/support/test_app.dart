import 'package:http/http.dart' as http;
import 'package:huella_cerca/app.dart';
import 'package:huella_cerca/core/di/service_registration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/core/storage/session_storage.dart';

/// Pruebas existentes de HTTP: composición real con transporte/almacenamiento simulados.
HuellaCercaApp testApp({
  required http.Client httpClient,
  required SessionStorage sessionStorage,
}) {
  configurarServicios(httpClient: httpClient, sessionStorage: sessionStorage);
  addTearDown(() => getIt.reset());
  return const HuellaCercaApp();
}
