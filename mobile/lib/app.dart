import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'pages/inicio_page.dart';
import 'services/ubicacion_service.dart';
import 'services/auth_service.dart';
import 'core/storage/session_storage.dart';
import 'pages/login_page.dart';
import 'pages/registro_page.dart';
import 'pages/perfil_page.dart';

/// Widget raíz: crea dependencias compartidas y configura tema y pantalla inicial.
class HuellaCercaApp extends StatefulWidget {
  const HuellaCercaApp({super.key, this.httpClient, this.sessionStorage});
  final SessionStorage? sessionStorage;
  // Permite usar un cliente simulado en las pruebas.
  final http.Client? httpClient;

  @override
  State<HuellaCercaApp> createState() => _HuellaCercaAppState();
}

class _HuellaCercaAppState extends State<HuellaCercaApp> {
  late final ApiClient _api;
  late final UbicacionService _ubicacion;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: ApiConfig.baseUrl, client: widget.httpClient);
    _ubicacion = UbicacionService(_api);
    _auth = AuthService(_api, widget.sessionStorage ?? SecureSessionStorage());
    _auth.restaurar();
  }

  @override
  void dispose() {
    _auth.dispose();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Huella Cerca',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF246653)),
      scaffoldBackgroundColor: const Color(0xFFF6F5F0),
      useMaterial3: true,
    ),
    home: InicioPage(api: _api, ubicacion: _ubicacion, auth: _auth),
    routes: {
      '/login': (_) => LoginPage(auth: _auth),
      '/registro': (_) => RegistroPage(auth: _auth, ubicacion: _ubicacion),
      '/perfil': (_) => PerfilPage(auth: _auth),
    },
  );
}
