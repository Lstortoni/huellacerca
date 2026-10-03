import 'dart:async';

import 'package:flutter/material.dart';

import 'services/contracts/push_service.dart';
import 'models/aviso_push.dart';
import 'pages/publicacion_detalle_page.dart';

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
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final List<StreamSubscription<AvisoPush>> _pushSubscriptions = [];
  PushService? _push;
  AvisoPush? _aperturaPendiente;
  bool _abriendoPush = false, _loginPush = false;
  // Opcional: las pruebas que no lo registran funcionan sin campanita.
  final NotificacionService? _notificaciones =
      getIt.isRegistered<NotificacionService>()
      ? getIt<NotificacionService>()
      : null;
  AppLifecycleListener? _ciclo;

  @override
  void initState() {
    super.initState();
    getIt<AuthService>().addListener(_sesionPushCambio);
    getIt<AuthService>().restaurar();
    if (getIt.isRegistered<PushService>()) {
      _push = getIt<PushService>();
      _pushSubscriptions.add(
        _push!.recibidos.listen((aviso) {
          _notificaciones?.actualizar();
          _messenger.currentState?.showSnackBar(
            SnackBar(
              content: const Text(
                'Hay una nueva posible coincidencia con tu aviso.',
              ),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () => _recibirApertura(aviso),
              ),
            ),
          );
        }),
      );
      _pushSubscriptions.add(_push!.abiertos.listen(_recibirApertura));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_push!.iniciar());
      });
    }
    final notificaciones = _notificaciones;
    if (notificaciones != null) {
      // En segundo plano no se consulta; al volver se actualiza enseguida.
      _ciclo = AppLifecycleListener(
        onHide: notificaciones.pausar,
        onResume: () {
          notificaciones.reanudar();
          unawaited(_push?.sincronizar());
        },
      );
    }
  }

  @override
  void dispose() {
    getIt<AuthService>().removeListener(_sesionPushCambio);
    for (final sub in _pushSubscriptions) {
      unawaited(sub.cancel());
    }
    _ciclo?.dispose();
    // Sin la app en pantalla no se consulta (también libera el temporizador).
    _notificaciones?.pausar();
    super.dispose();
  }

  void _recibirApertura(AvisoPush aviso) {
    _aperturaPendiente = aviso;
    _sesionPushCambio();
  }

  void _sesionPushCambio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_abrirPush());
    });
    // También atender eventos recibidos cuando no había un frame programado.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _abrirPush() async {
    final aviso = _aperturaPendiente;
    final auth = getIt<AuthService>();
    final nav = _navigator.currentState;
    if (aviso == null ||
        nav == null ||
        _abriendoPush ||
        auth.restaurando ||
        auth.ocupado) {
      return;
    }
    if (!auth.autenticado) {
      if (_loginPush) return;
      _loginPush = true;
      await nav.pushNamed('/login');
      _loginPush = false;
      if (!mounted) return;
      if (auth.autenticado) {
        _sesionPushCambio();
      } else {
        _aperturaPendiente = null;
      }
      return;
    }
    // Nunca abrir datos de una notificación de la cuenta anterior en este teléfono.
    if (auth.usuario?.mascotero.id != aviso.mascoteroId) {
      _aperturaPendiente = null;
      _messenger.currentState?.showSnackBar(
        const SnackBar(content: Text('Este aviso corresponde a otra cuenta.')),
      );
      return;
    }
    _abriendoPush = true;
    _aperturaPendiente = null;
    try {
      final destino = await auth.getProtegido(
        'api/notificaciones/${aviso.notificacionId}/destino',
      ) as Map<String, dynamic>;
      if (!mounted || auth.usuario?.mascotero.id != aviso.mascoteroId) return;
      await auth.patchProtegido(
        'api/notificaciones/${aviso.notificacionId}/leer',
      );
      if (!mounted || auth.usuario?.mascotero.id != aviso.mascoteroId) return;
      unawaited(_notificaciones?.actualizar());
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => PublicacionDetallePage(
            id: destino['publicacionId'] as String,
            auth: auth,
            service: getIt<PublicacionService>(),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _messenger.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos abrir el aviso. Podés volver a intentarlo desde la campanita.',
            ),
          ),
        );
      }
    } finally {
      _abriendoPush = false;
      if (mounted && _aperturaPendiente != null) _sesionPushCambio();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    scaffoldMessengerKey: _messenger,
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
