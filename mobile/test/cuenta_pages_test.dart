import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/test_app.dart';

import 'package:huella_cerca/models/provincia_dto.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/services/implementations/ubicacion_service_api.dart';
import 'package:huella_cerca/widgets/selector_localidad.dart';

import 'support/auth_fakes.dart';

http.Response json(Object? data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  testWidgets('Formulario de registro envía datos y localidad elegida', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final storage = MemorySessionStorage();
    final client = MockClient((r) async {
      if (r.url.path == '/health') return http.Response('Healthy', 200);
      if (r.url.path == '/api/provincias') {
        return json([
          {'id': 'p1', 'nombre': 'Córdoba', 'paisCodigo': 'AR'},
        ]);
      }
      if (r.url.path == '/api/localidades') {
        return json({
          'items': [
            {'id': 'l1', 'nombre': 'Villa Prueba', 'provinciaId': 'p1'},
          ],
          'total': 1,
        });
      }
      if (r.url.path == '/api/auth/register') {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return json(sesionJson(), 201);
      }
      return json({}, 404);
    });
    await tester.pumpWidget(
      testApp(httpClient: client, sessionStorage: storage),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrarse').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    final values = [
      'Ana',
      'Prueba',
      'prueba@example.com',
      '2211234567',
      '12345678',
      '12345678',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.ensureVisible(fields.at(i));
      await tester.enterText(fields.at(i), values[i]);
    }
    final province = find.byType(DropdownButtonFormField<ProvinciaDto>);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(province);
    await tester.pumpAndSettle();
    await tester.tap(province);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Córdoba').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Elegir localidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir localidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa Prueba'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(sent?['localidadId'], 'l1');
    expect(sent?['nombre'], 'Ana');
    expect(sent?['passwordConfirm'], '12345678');
    expect(storage.value, isNotNull);
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
  });
  testWidgets(
    'Inicio público, login, perfil y logout actualizan la barra compartida',
    (tester) async {
      final storage = MemorySessionStorage();
      final client = MockClient((r) async {
        switch (r.url.path) {
          case '/health':
            return http.Response('Healthy', 200);
          case '/api/provincias':
            return json([
              {'id': 'p1', 'nombre': 'Córdoba', 'paisCodigo': 'AR'},
            ]);
          case '/api/auth/login':
            return json(sesionJson());
          case '/api/auth/me':
            return json(usuarioJson());
          case '/api/auth/logout':
            return http.Response('', 204);
          default:
            return json({}, 404);
        }
      });
      await tester.pumpWidget(
        testApp(httpClient: client, sessionStorage: storage),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buscar mascotas'), findsOneWidget);
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Registrarse'), findsWidgets);
      await tester.tap(find.text('Ingresar').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'prueba@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '12345678');
      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresar'), findsNothing);
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Prueba'), findsOneWidget);
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(storage.value, isNull);
      expect(find.text('Buscar mascotas'), findsOneWidget);
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresar'), findsWidgets);
    },
  );

  testWidgets('Registro exige localidad antes de enviar', (tester) async {
    var registrations = 0;
    final client = MockClient((r) async {
      if (r.url.path == '/health') return http.Response('Healthy', 200);
      if (r.url.path == '/api/auth/register') {
        registrations++;
        return json(sesionJson());
      }
      return json([
        {'id': 'p1', 'nombre': 'Córdoba', 'paisCodigo': 'AR'},
      ]);
    });
    await tester.pumpWidget(
      testApp(httpClient: client, sessionStorage: MemorySessionStorage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrarse').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Crear cuenta'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí una localidad.'), findsOneWidget);
    expect(registrations, 0);
  });

  testWidgets(
    'Localidades permite buscar y avanzar más allá de la primera página',
    (tester) async {
      final requests = <Map<String, String>>[];
      final api = HttpApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          requests.add(r.url.queryParameters);
          final page = r.url.queryParameters['pagina'];
          return json({
            'items': [
              {
                'id': 'l$page',
                'nombre': 'Localidad $page',
                'provinciaId': 'p1',
              },
            ],
            'total': 21,
          });
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectorLocalidad(
              ubicacion: UbicacionServiceApi(api),
              provinciaId: 'p1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Localidad 2'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'villa');
      await tester.tap(find.byTooltip('Buscar'));
      await tester.pumpAndSettle();
      expect(requests.last, containsPair('pagina', '1'));
      expect(requests.last, containsPair('busqueda', 'villa'));
      expect(requests.last, containsPair('provinciaId', 'p1'));
    },
  );
}
