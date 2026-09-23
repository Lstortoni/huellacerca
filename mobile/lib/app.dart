import 'package:flutter/material.dart';

import 'core/di/service_registration.dart';
import 'core/theme/colores_app.dart';
import 'services/contracts/auth_service.dart';
import 'services/contracts/ubicacion_service.dart';
import 'pages/inicio_page.dart';
import 'pages/login_page.dart';
import 'pages/registro_page.dart';
import 'pages/perfil_page.dart';
import 'pages/mascotas_page.dart';
import 'pages/mis_publicaciones_page.dart';
import 'pages/publicar_mascota_page.dart';
import 'pages/recomendaciones_page.dart';
import 'pages/recomendar_servicio_page.dart';
import 'services/contracts/publicacion_service.dart';
import 'services/contracts/recomendacion_service.dart';

/// Widget raíz: resuelve contratos y configura tema, inicio y rutas.
class HuellaCercaApp extends StatefulWidget {
  const HuellaCercaApp({super.key});

  @override
  State<HuellaCercaApp> createState() => _HuellaCercaAppState();
}

class _HuellaCercaAppState extends State<HuellaCercaApp> {
  @override
  void initState() {
    super.initState();
    getIt<AuthService>().restaurar();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Huella Cerca',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: ColoresApp.verde),
      scaffoldBackgroundColor: ColoresApp.fondo,
      // Barra integrada al fondo, sin el tinte gris al desplazar.
      appBarTheme: const AppBarTheme(
        backgroundColor: ColoresApp.fondo,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ColoresApp.verde,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      useMaterial3: true,
    ),
    home: InicioPage(auth: getIt<AuthService>()),
    routes: {
      '/login': (_) => LoginPage(auth: getIt<AuthService>()),
      '/registro': (_) => RegistroPage(
        auth: getIt<AuthService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
      '/perfil': (_) => PerfilPage(auth: getIt<AuthService>()),
      '/mascotas': (_) => MascotasPage(
        auth: getIt<AuthService>(),
        service: getIt<PublicacionService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
      '/servicios': (_) => RecomendacionesPage(
        auth: getIt<AuthService>(),
        service: getIt<RecomendacionService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
      '/mascotas/mias': (_) => MisPublicacionesPage(
        auth: getIt<AuthService>(),
        service: getIt<PublicacionService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
      '/mascotas/publicar': (_) => PublicarMascotaPage(
        auth: getIt<AuthService>(),
        service: getIt<PublicacionService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
      '/servicios/recomendar': (_) => RecomendarServicioPage(
        auth: getIt<AuthService>(),
        service: getIt<RecomendacionService>(),
        ubicacion: getIt<UbicacionService>(),
      ),
    },
  );
}
