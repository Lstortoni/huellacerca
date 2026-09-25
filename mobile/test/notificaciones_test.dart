import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/notificacion_dto.dart';
import 'package:huella_cerca/pages/notificaciones_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/services/implementations/notificacion_service_api.dart';
import 'package:huella_cerca/widgets/barra_superior.dart';
import 'package:huella_cerca/widgets/notificaciones_scope.dart';

import 'comunidad_pages_test.dart' show tapVisible;
import 'support/comunidad_mocks.dart';
import 'support/notificaciones_mocks.dart';
import 'support/service_mocks.dart';

/// Sesión simulada que responde los endpoints de notificaciones.
class AuthNotificaciones extends AuthServiceMock {
  int cantidad = 3;
  bool falla = false;
  final rutas = <String>[];
  int get consultasContador =>
      rutas.where((r) => r.endsWith('no-leidas/cantidad')).length;

  @override
  Future<Object?> getProtegido(String path) async {
    rutas.add(path);
    if (falla) throw Exception('Sin conexión');
    if (path.startsWith('api/notificaciones?')) {
      return {
        'items': [notificacionJson()],
        'total': 1,
        'pagina': 1,
        'tamanoPagina': 20,
      };
    }
    return {'cantidad': cantidad};
  }

  @override
  Future<Object?> patchProtegido(String path) async {
    rutas.add('PATCH $path');
    return null;
  }
}

const _login = LoginRequest('a@b.com', '12345678');

void main() {
  test('DTO resume ambos avisos y el estado de lectura', () {
    final n = NotificacionDto.fromJson(notificacionJson());
    expect(n.leida, isFalse);
    expect(n.publicacion.titulo, 'Toby');
    expect(n.coincidente.titulo, 'Perro'); // Sin nombre: usa la especie.
    expect(n.coincidente.tipoPublicacion, 2);
    expect(NotificacionDto.fromJson(notificacionJson(leida: true)).leida, true);
  });

  testWidgets('Contador: consulta con sesión, cada 2 minutos, pausa y logout', (
    tester,
  ) async {
    final auth = AuthNotificaciones();
    final servicio = NotificacionServiceApi(auth);
    addTearDown(auth.dispose);
    addTearDown(servicio.dispose);
    expect(auth.consultasContador, 0); // Sin sesión no consulta.
    await auth.login(_login);
    await tester.pump();
    expect(servicio.noLeidas, 3);
    expect(auth.consultasContador, 1);
    auth.cantidad = 5;
    await tester.pump(const Duration(minutes: 2));
    expect(servicio.noLeidas, 5);
    expect(auth.consultasContador, 2);
    servicio.pausar();
    await tester.pump(const Duration(minutes: 5));
    expect(auth.consultasContador, 2);
    servicio.reanudar(); // Al volver a la app consulta enseguida.
    await tester.pump();
    expect(auth.consultasContador, 3);
    auth
      ..falla = true
      ..cantidad = 9;
    await tester.pump(const Duration(minutes: 2));
    expect(servicio.noLeidas, 5); // Un fallo conserva el último valor.
    await auth.logout();
    expect(servicio.noLeidas, 0);
    final consultas = auth.consultasContador;
    await tester.pump(const Duration(minutes: 4));
    expect(auth.consultasContador, consultas);
  });

  test('Lecturas: baja el contador, no repite y marca todas', () async {
    final auth = AuthNotificaciones()..cantidad = 2;
    await auth.login(_login);
    final servicio = NotificacionServiceApi(auth);
    addTearDown(auth.dispose);
    addTearDown(servicio.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(servicio.noLeidas, 2);
    await servicio.marcarLeida(NotificacionDto.fromJson(notificacionJson()));
    expect(servicio.noLeidas, 1);
    expect(auth.rutas.last, 'PATCH api/notificaciones/n1/leer');
    final patches = auth.rutas.where((r) => r.startsWith('PATCH')).length;
    await servicio.marcarLeida(
      NotificacionDto.fromJson(notificacionJson(leida: true)),
    );
    expect(servicio.noLeidas, 1);
    expect(auth.rutas.where((r) => r.startsWith('PATCH')).length, patches);
    await servicio.marcarTodas();
    expect(servicio.noLeidas, 0);
    expect(auth.rutas.last, 'PATCH api/notificaciones/leer-todas');
    final pagina = await servicio.listar(soloNoLeidas: true);
    expect(auth.rutas.last, contains('soloNoLeidas=true'));
    expect(pagina.items.single.coincidente.id, 'publicacion-2');
  });

  testWidgets(
    'Campanita: solo con sesión, muestra el número y abre la página',
    (tester) async {
      final auth = AuthServiceMock();
      final notificaciones = NotificacionServiceMock();
      addTearDown(auth.dispose);
      addTearDown(notificaciones.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) =>
              NotificacionesScope(notifier: notificaciones, child: child!),
          home: Scaffold(appBar: BarraSuperior(auth: auth)),
          routes: {
            '/notificaciones': (_) =>
                const Scaffold(body: Text('Página de notificaciones')),
          },
        ),
      );
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      await auth.login(_login);
      await tester.pump();
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      notificaciones.noLeidas = 3;
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      notificaciones.noLeidas = 150;
      await tester.pump();
      expect(find.text('99+'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Página de notificaciones'), findsOneWidget);
    },
  );

  group('Página de notificaciones', () {
    late AuthServiceMock auth;
    late NotificacionServiceMock notificaciones;
    setUp(() async {
      auth = AuthServiceMock();
      notificaciones = NotificacionServiceMock();
      await auth.login(_login);
    });
    tearDown(() {
      auth.dispose();
      notificaciones.dispose();
    });
    Future<void> abrir(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificacionesPage(
            auth: auth,
            notificaciones: notificaciones,
            publicaciones: PublicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Sin notificaciones explica cuándo llegan', (tester) async {
      await abrir(tester);
      expect(notificaciones.actualizaciones, 1); // Actualiza al entrar.
      expect(
        find.textContaining('Todavía no tenés notificaciones'),
        findsOneWidget,
      );
      expect(find.text('Marcar todas como leídas'), findsNothing);
    });

    testWidgets('Tocar abre el aviso que coincide y lo marca leído', (
      tester,
    ) async {
      notificaciones
        ..items = [NotificacionDto.fromJson(notificacionJson())]
        ..noLeidas = 1;
      await abrir(tester);
      expect(find.text('Posible coincidencia con Toby'), findsOneWidget);
      expect(find.text('Encontrada'), findsOneWidget); // Tipo del que coincide.
      await tapVisible(tester, find.text('Posible coincidencia con Toby'));
      expect(notificaciones.leidas, ['n1']);
      expect(
        tester
            .widget<PublicacionDetallePage>(find.byType(PublicacionDetallePage))
            .id,
        'publicacion-2',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Ver mi aviso: Toby'));
      expect(
        tester
            .widget<PublicacionDetallePage>(find.byType(PublicacionDetallePage))
            .id,
        'publicacion-1',
      );
    });

    testWidgets('Filtra no leídas, marca todas y muestra resueltas', (
      tester,
    ) async {
      notificaciones
        ..items = [
          NotificacionDto.fromJson(notificacionJson(estadoCoincidente: 2)),
        ]
        ..noLeidas = 1;
      await abrir(tester);
      expect(find.text('Resuelta'), findsOneWidget);
      await tapVisible(tester, find.text('No leídas'));
      expect(notificaciones.consultas.last, isTrue);
      await tapVisible(tester, find.text('Marcar todas como leídas'));
      expect(notificaciones.todas, 1);
      expect(find.text('Marcar todas como leídas'), findsNothing);
    });
  });
}
