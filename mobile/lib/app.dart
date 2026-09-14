import 'package:flutter/material.dart';

import 'core/di/service_registration.dart';
import 'services/contracts/auth_service.dart';
import 'services/contracts/ubicacion_service.dart';
import 'pages/inicio_page.dart';
import 'pages/login_page.dart';
import 'pages/registro_page.dart';
import 'pages/perfil_page.dart';
import 'pages/funcion_pendiente_page.dart';

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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF246653)),
      scaffoldBackgroundColor: const Color(0xFFF6F5F0),
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
      '/mascotas': (_) => FuncionPendientePage(
        auth: getIt<AuthService>(),
        titulo: 'Buscar mascotas',
        icono: Icons.pets_outlined,
        descripcion: 'Acá vas a poder buscar mascotas perdidas y encontradas por ubicación.',
      ),
      '/servicios': (_) => FuncionPendientePage(
        auth: getIt<AuthService>(),
        titulo: 'Servicios recomendados',
        icono: Icons.storefront_outlined,
        descripcion: 'Acá vas a poder buscar servicios recomendados por rubro y ubicación.',
      ),
      '/mascotas/publicar': (_) => FuncionPendientePage(
        auth: getIt<AuthService>(),
        titulo: 'Publicar mascota',
        icono: Icons.campaign_outlined,
        requiereSesion: true,
        descripcion:
            'Acá vas a poder publicar una mascota perdida o encontrada.',
      ),
      '/servicios/recomendar': (_) => FuncionPendientePage(
        auth: getIt<AuthService>(),
        titulo: 'Recomendar un servicio',
        icono: Icons.rate_review_outlined,
        requiereSesion: true,
        descripcion: 'Acá vas a poder compartir tu recomendación de un servicio para mascotas.',
      ),
    },
  );
}
