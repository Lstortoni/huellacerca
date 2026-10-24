import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/test_app.dart';

import 'comunidad_pages_test.dart' show elegirLocalidad;
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // Sin elegir provincia: se escribe la ciudad directamente.
    await elegirLocalidad(tester, busqueda: 'Villa', opcion: 'Villa Prueba');
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
      // Iniciales: avatar de la barra (botón de la cuenta) y del perfil.
      expect(find.text('AP'), findsNWidgets(2));
      expect(find.text('Email sin confirmar'), findsOneWidget);
      expect(find.text('Accesos rápidos'), findsOneWidget);
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      // El perfil también tiene un botón «Cerrar sesión»: usar el del menú.
      await tester.tap(
        find.widgetWithText(PopupMenuItem<String>, 'Cerrar sesión'),
      );
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
}
