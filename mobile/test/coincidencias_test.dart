import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';

import 'support/auth_fakes.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/models/pagina_dto.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';

import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';
import 'publicar_caracteristicas_test.dart' show completar, elegir;
import 'comunidad_pages_test.dart' show tapVisible;

class CoincidenciasMock extends PublicacionServiceMock {
  int tipo = 1;
  @override
  Future<PublicacionDto> detalle(String id) async => PublicacionDto.fromJson({
    ...publicacionJson(estado: estado, autorId: autorId),
    'tipoPublicacion': tipo,
  });
  int llamadas = 0;
  bool falla = false;
  @override
  Future<PaginaDto<CoincidenciaPublicacionDto>> coincidencias(
    String id, {
    int pagina = 1,
    int tamanoPagina = 10,
  }) async {
    llamadas++;
    if (falla) throw Exception('Sin conexión');
    return PaginaDto(
      [
        CoincidenciaPublicacionDto.fromJson({
          'publicacion': {
            ...publicacionJson(),
            'id': 'candidato',
            'nombreMascota': 'Candidato marrón',
            'tipoPublicacion': 2,
          },
          'coincideEn': ['Color predominante'],
        }),
      ],
      1,
      pagina,
      tamanoPagina,
    );
  }
}

void main() {
  for (final tipo in [1, 2, 3, 4]) {
    testWidgets('Aviso resuelto de tipo $tipo no consulta coincidencias', (
      tester,
    ) async {
      final auth = AuthServiceMock();
      final service = CoincidenciasMock()..tipo = tipo;
      service.estado = 2;
      addTearDown(auth.dispose);
      await auth.login(const LoginRequest('a@b.com', '12345678'));
      await tester.pumpWidget(
        MaterialApp(
          home: PublicacionDetallePage(
            id: 'publicacion-1',
            auth: auth,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Posibles coincidencias'), findsOneWidget);
      expect(find.textContaining('Ya no se consultan'), findsOneWidget);
      expect(service.llamadas, 0);
    });
  }
  test('Consulta HTTP conserva paginación y envía JWT', () async {
    final api = HttpApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        if (r.url.path.endsWith('/me')) {
          return http.Response(jsonEncode(usuarioJson()), 200);
        }
        expect(r.url.path, '/api/publicaciones/p1/coincidencias');
        expect(r.url.queryParameters, {'pagina': '2', 'tamanoPagina': '5'});
        expect(r.headers['Authorization'], 'Bearer access-1');
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'pagina': 2, 'tamanoPagina': 5}),
          200,
        );
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
    final result = await PublicacionServiceApi(
      api,
      auth,
    ).coincidencias('p1', pagina: 2, tamanoPagina: 5);
    expect(result.pagina, 2);
  });
  for (final tipo in tiposPublicacion.entries) {
    testWidgets(
      'Publicar ${tipo.value} consulta coincidencias y reabrir vuelve a consultar',
      (tester) async {
        final auth = AuthServiceMock();
        final service = CoincidenciasMock()..tipo = tipo.key;
        addTearDown(auth.dispose);
        await auth.login(const LoginRequest('a@b.com', '12345678'));
        await tester.pumpWidget(
          MaterialApp(
            home: PublicarMascotaPage(
              auth: auth,
              service: service,
              ubicacion: UbicacionServiceMock(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await elegir(tester, '¿Qué querés publicar?', tipo.value);
        await completar(tester);
        if (tipo.key <= 2) {
          await tapVisible(tester, find.text('Elegir fecha'));
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        }
        await tapVisible(tester, find.text('Publicar aviso'));
        expect(find.text('Posibles coincidencias'), findsOneWidget);
        expect(find.text('Candidato marrón'), findsOneWidget);
        expect(service.llamadas, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            home: PublicacionDetallePage(
              id: 'publicacion-1',
              auth: auth,
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(service.llamadas, 2);
        expect(find.text('Candidato marrón'), findsOneWidget);
      },
    );
  }
  testWidgets('Un error permite reintentar sin ocultar el contacto', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = CoincidenciasMock()..falla = true;
    addTearDown(auth.dispose);
    await auth.login(const LoginRequest('a@b.com', '12345678'));
    await tester.pumpWidget(
      MaterialApp(
        home: PublicacionDetallePage(
          id: 'publicacion-1',
          auth: auth,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2215550000'), findsOneWidget);
    service.falla = false;
    await tapVisible(tester, find.text('Reintentar coincidencias'));
    expect(find.text('Candidato marrón'), findsOneWidget);
  });
}
