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
import 'services/contracts/notificacion_service.dart';
import 'models/publicacion_dto.dart';
import 'pages/notificaciones_page.dart';
import 'widgets/notificaciones_scope.dart';

/// Widget raíz: resuelve contratos y configura tema, inicio y rutas.
class HuellaCercaApp extends StatefulWidget {
  const HuellaCercaApp({super.key});

  @override
  State<HuellaCercaApp> createState() => _HuellaCercaAppState();
}

class _HuellaCercaAppState extends State<HuellaCercaApp> {
  // Opcional: las pruebas que no lo registran funcionan sin campanita.
  final NotificacionService? _notificaciones =
      getIt.isRegistered<NotificacionService>()
      ? getIt<NotificacionService>()
      : null;
  AppLifecycleListener? _ciclo;

  @override
  void initState() {
    super.initState();
    getIt<AuthService>().restaurar();
    final notificaciones = _notificaciones;
    if (notificaciones != null) {
      // En segundo plano no se consulta; al volver se actualiza enseguida.
      _ciclo = AppLifecycleListener(
        onHide: notificaciones.pausar,
        onResume: notificaciones.reanudar,
      );
    }
  }

  @override
  void dispose() {
    _ciclo?.dispose();
    // Sin la app en pantalla no se consulta (también libera el temporizador).
    _notificaciones?.pausar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Huella Cerca',
    debugShowCheckedModeBanner: false,
    builder: (context, child) => _notificaciones == null
        ? child!
        : NotificacionesScope(notifier: _notificaciones, child: child!),
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
      // Campos con fondo blanco y bordes redondeados en toda la app.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
      // Argumento: el PublicacionDto a editar. Devuelve el aviso actualizado.
      '/mascotas/editar': (context) => PublicarMascotaPage(
        auth: getIt<AuthService>(),
        service: getIt<PublicacionService>(),
        ubicacion: getIt<UbicacionService>(),
        edicion: ModalRoute.of(context)!.settings.arguments! as PublicacionDto,
      ),
      '/notificaciones': (_) => NotificacionesPage(
        auth: getIt<AuthService>(),
        notificaciones: getIt<NotificacionService>(),
        publicaciones: getIt<PublicacionService>(),
      ),
    },
  );
}
