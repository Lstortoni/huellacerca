import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/app.dart';

http.Response provincias() => http.Response(
  jsonEncode([
    {'id': 'provincia-1', 'nombre': 'Córdoba', 'paisCodigo': 'AR'},
  ]),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('Carga desde la API y permite elegir una provincia', (
    tester,
  ) async {
    final health = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path == '/health') return health.future;
      expect(request.url.path, '/api/provincias');
      expect(request.url.queryParameters, {'paisCodigo': 'AR'});
      return provincias();
    });
    await tester.pumpWidget(HuellaCercaApp(httpClient: client));
    expect(find.text('Cargando provincias…'), findsOneWidget);
    health.complete(http.Response('Healthy', 200));
    await tester.pumpAndSettle();
    expect(find.text('1 provincias disponibles'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonHideUnderline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Córdoba').last);
    await tester.pumpAndSettle();
    expect(find.text('Elegiste Córdoba.'), findsOneWidget);
  });

  testWidgets('Error de red seguido de reintento exitoso', (tester) async {
    var healthCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        if (++healthCalls == 1) throw http.ClientException('sin conexión');
        return http.Response('Healthy', 200);
      }
      return provincias();
    });
    await tester.pumpWidget(HuellaCercaApp(httpClient: client));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Seleccioná una provincia'), findsOneWidget);
    expect(healthCalls, 2);
  });

  testWidgets('Catálogo vacío tiene un mensaje y permite volver a consultar', (
    tester,
  ) async {
    final client = MockClient(
      (r) async =>
          http.Response(r.url.path == '/health' ? 'Healthy' : '[]', 200),
    );
    await tester.pumpWidget(HuellaCercaApp(httpClient: client));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay provincias disponibles.'), findsOneWidget);
    expect(find.text('Volver a consultar'), findsOneWidget);
  });

  testWidgets('Respuesta posterior a cerrar la pantalla no llama setState', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      HuellaCercaApp(httpClient: MockClient((_) => response.future)),
    );
    await tester.pumpWidget(const SizedBox());
    response.complete(http.Response('Healthy', 200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
