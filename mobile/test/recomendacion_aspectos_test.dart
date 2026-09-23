import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/recomendacion_dto.dart';
import 'package:huella_cerca/pages/prestador_detalle_page.dart';
import 'package:huella_cerca/pages/recomendaciones_page.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/recomendacion_service_api.dart';

import 'support/auth_fakes.dart';
import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';

/// Fila del resumen de aspectos con su cantidad de votos.
Finder aspecto(String nombre, int cantidad) => find.descendant(
  of: find.byKey(ValueKey('aspecto:$nombre')),
  matching: find.text('$cantidad'),
);

Future<void> tocar(WidgetTester tester, String texto) async {
  // Esperar el aviso temporal antes de tocar controles al pie de la pantalla.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  // La gestión va antes que el resumen: el primero es el control editable.
  final finder = find.text(texto).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final conSesion in [false, true]) {
    testWidgets('Consulta pública es solo lectura, con sesión: $conSesion', (
      tester,
    ) async {
      final auth = AuthServiceMock();
      final service = RecomendacionServiceMock();
      addTearDown(auth.dispose);
      await service.crear(
        const CrearRecomendacionRequest(prestadorServicioId: 'prestador-1'),
      );
      await service.guardarAspectos('recomendacion-1', ['a1']);
      if (conSesion) {
        await auth.login(const LoginRequest('a@b.com', '12345678'));
      }
      await tester.pumpWidget(
        MaterialApp(
          home: RecomendacionesPage(
            auth: auth,
            service: service,
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tocar(tester, 'Veterinaria del barrio');
      expect(find.byType(PrestadorDetallePage), findsOneWidget);
      expect(find.text('1 persona lo recomienda'), findsOneWidget);
      expect(aspecto('Buena atención', 1), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Personas que lo recomiendan'), findsOneWidget);
      expect(find.text('Recomendar'), findsNothing);
      expect(find.text('Guardar aspectos'), findsNothing);
      expect(find.text('Retirar recomendación'), findsNothing);
      expect(find.text('Ingresá para recomendar'), findsNothing);
      expect(find.text('Tu recomendación'), findsNothing);
      expect(service.consultasPropias, 0);
    });
  }

  test('Mías conserva query y JWT; PUT renueva y DELETE acepta 204', () async {
    var puts = 0, refreshes = 0;
    final api = HttpApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        http.Response json(Object value, [int status = 200]) => http.Response(
          jsonEncode(value),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
        switch (r.url.path) {
          case '/api/auth/me':
            return json(usuarioJson());
          case '/api/auth/refresh':
            refreshes++;
            return json(sesionJson(token: 'access-2'));
          case '/api/aspectos-recomendacion':
            expect(r.headers['Authorization'], isNull);
            return json([
              {'id': 'a1', 'nombre': 'Buena atención', 'activo': true},
            ]);
          case '/api/recomendaciones/mias':
            expect(r.url.queryParameters, {
              'prestadorServicioId': 'prestador-1',
            });
            expect(r.headers['Authorization'], 'Bearer access-1');
            return json({
              'items': [recomendacionJson()],
            });
          case '/api/recomendaciones/recomendacion-1/aspectos':
            expect(r.method, 'PUT');
            expect(jsonDecode(r.body), {'aspectoIds': []});
            puts++;
            if (puts == 1) return json({}, 401);
            expect(r.headers['Authorization'], 'Bearer access-2');
            return json(recomendacionJson());
          case '/api/recomendaciones/recomendacion-1':
            expect(r.method, 'DELETE');
            expect(r.headers['Authorization'], 'Bearer access-2');
            expect(r.body, isEmpty);
            return http.Response('', 204);
          default:
            throw StateError('Llamada inesperada: ${r.url}');
        }
      }),
    );
    final auth = AuthServiceApi(
      api,
      MemorySessionStorage()..value = sesionTexto(),
    );
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    final service = RecomendacionServiceApi(api, auth);
    expect((await service.aspectos()).single.nombre, 'Buena atención');
    expect(
      (await service.miRecomendacion('prestador-1'))!.id,
      'recomendacion-1',
    );
    expect(
      (await service.guardarAspectos('recomendacion-1', [])).aspectos,
      isEmpty,
    );
    expect(puts, 2);
    expect(refreshes, 1);
    await service.retirar('recomendacion-1');
  });

  testWidgets(
    'Recomendar sin aspectos cuenta; editar, vaciar y retirar actualiza totales',
    (tester) async {
      final auth = AuthServiceMock();
      final service = RecomendacionServiceMock();
      addTearDown(auth.dispose);
      await auth.login(const LoginRequest('a@b.com', '12345678'));
      await tester.pumpWidget(
        MaterialApp(
          home: PrestadorDetallePage(
            permitirGestion: true,
            id: 'prestador-1',
            auth: auth,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tocar(tester, 'Recomendar');
      expect(service.mia, isNotNull);
      expect(service.mia!.aspectos, isEmpty);
      expect(service.creaciones, 1);
      expect(find.text('1 persona lo recomienda'), findsOneWidget);
      expect(find.text('Ya lo recomendás'), findsOneWidget);
      expect(find.text('Recomendar'), findsNothing);
      await tocar(tester, 'Buena atención');
      await tocar(tester, 'Guardar aspectos');
      expect(service.guardados, ['a1']);
      expect(aspecto('Buena atención', 1), findsOneWidget);
      await tocar(tester, 'Buena atención');
      await tocar(tester, 'Guardar aspectos');
      expect(service.guardados, isEmpty);
      expect(find.text('1 persona lo recomienda'), findsOneWidget);
      expect(aspecto('Buena atención', 1), findsNothing);
      await tocar(tester, 'Retirar recomendación');
      await tocar(tester, 'Retirar');
      expect(service.retiros, 1);
      expect(find.text('0 personas lo recomiendan'), findsOneWidget);
      expect(find.text('Recomendar'), findsOneWidget);
    },
  );

  testWidgets(
    'Visitante ve ficha; fallo de consulta propia permite reintentar sin crear duplicados',
    (tester) async {
      final auth = AuthServiceMock();
      final service = RecomendacionServiceMock()..falloConsulta = true;
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: PrestadorDetallePage(
            permitirGestion: true,
            id: 'prestador-1',
            auth: auth,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Veterinaria del barrio'), findsOneWidget);
      expect(find.text('Ingresá para recomendar'), findsOneWidget);
      await auth.login(const LoginRequest('a@b.com', '12345678'));
      await tester.pumpAndSettle();
      expect(find.text('Recomendar'), findsNothing);
      service.falloConsulta = false;
      service.mia = RecomendacionDto.fromJson(recomendacionJson());
      await tocar(tester, 'Revisar mi recomendación');
      expect(find.text('Ya lo recomendás'), findsOneWidget);
      expect(service.creaciones, 0);
      await auth.logout();
      await tester.pumpAndSettle();
      expect(find.text('Guardar aspectos'), findsNothing);
      expect(find.text('Ingresá para recomendar'), findsOneWidget);
    },
  );

  testWidgets('Si falla catálogo el voto sigue guardado y permite reintentar', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = RecomendacionServiceMock()..falloCatalogo = true;
    addTearDown(auth.dispose);
    await auth.login(const LoginRequest('a@b.com', '12345678'));
    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorDetallePage(
          permitirGestion: true,
          id: 'prestador-1',
          auth: auth,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tocar(tester, 'Recomendar');
    expect(service.mia, isNotNull);
    expect(find.text('Ya lo recomendás'), findsOneWidget);
    service.falloCatalogo = false;
    await tocar(tester, 'No pudimos cargar aspectos. Reintentar');
    expect(find.text('Buena atención'), findsOneWidget);
    expect(service.creaciones, 1);
  });
}
