import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'features/inicio/presentation/inicio_page.dart';
import 'features/ubicacion/services/ubicacion_service.dart';

/// Widget raíz: crea dependencias compartidas y configura tema y pantalla inicial.
class HuellaCercaApp extends StatefulWidget {
  const HuellaCercaApp({super.key, this.httpClient});
  // Permite usar un cliente simulado en las pruebas.
  final http.Client? httpClient;

  @override
  State<HuellaCercaApp> createState() => _HuellaCercaAppState();
}

class _HuellaCercaAppState extends State<HuellaCercaApp> {
  late final ApiClient _api;
  late final UbicacionService _ubicacion;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: ApiConfig.baseUrl, client: widget.httpClient);
    _ubicacion = UbicacionService(_api);
  }

  @override
  void dispose() {
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
    home: InicioPage(api: _api, ubicacion: _ubicacion),
  );
}
