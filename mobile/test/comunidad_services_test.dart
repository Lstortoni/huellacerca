import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/core/network/api_exception.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/models/recomendacion_dto.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';
import 'package:huella_cerca/services/implementations/recomendacion_service_api.dart';

import 'support/auth_fakes.dart';
import 'support/comunidad_mocks.dart';

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  test('Consultas públicas, DTO y filtros coinciden con la API', () async {
    final api = HttpApiClient(
      baseUrl: 'http://localhost:5080/',
      client: MockClient((r) async {
        expect(r.method, 'GET');
        expect(r.headers['Authorization'], isNull);
        switch (r.url.path) {
          case '/api/publicaciones':
            expect(r.url.queryParameters, {
              'estado': '1',
              'localidadId': 'l1',
              'pagina': '2',
              'tamanoPagina': '20',
            });
            return response({
              'items': [publicacionJson()],
              'total': 21,
              'pagina': 2,
              'tamanoPagina': 20,
            });
          case '/api/publicaciones/publicacion-1':
            return response(publicacionJson());
          case '/api/rubros':
            return response([
              {'id': 'r1', 'nombre': 'Veterinaria'},
            ]);
          case '/api/prestadores/similares':
            expect(r.url.queryParameters, {
              'nombre': 'Los Tilos',
              'rubroId': 'r1',
              'localidadId': 'l1',
            });
            return response([prestadorJson()]);
          case '/api/recomendaciones':
            expect(r.url.queryParameters['rubroId'], 'r1');
            return response({
              'items': [recomendacionJson()],
              'total': 1,
              'pagina': 1,
              'tamanoPagina': 20,
            });
          default:
            return response(recomendacionJson());
        }
      }),
    );
    final auth = AuthServiceApi(api, MemorySessionStorage());
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    final publicaciones = PublicacionServiceApi(api, auth);
    final recomendaciones = RecomendacionServiceApi(api, auth);
    final page = await publicaciones.buscar(
      filtros: {'estado': '1', 'localidadId': 'l1'},
      pagina: 2,
    );
    expect(page.items.single.titulo, 'Toby');
    expect(page.haySiguiente, false);
    expect((await publicaciones.detalle('publicacion-1')).zona, 'Plaza');
    expect((await recomendaciones.rubros()).single.nombre, 'Veterinaria');
    expect(
      (await recomendaciones.similares(
        nombre: 'Los Tilos',
        rubroId: 'r1',
        localidadId: 'l1',
      )).single.id,
      'prestador-1',
    );
    expect(
      (await recomendaciones.buscar(filtros: {'rubroId': 'r1'}))
          .items
          .single
          .autor,
      'Ana',
    );
    expect(
      (await recomendaciones.detalle('recomendacion-1')).prestador.nombre,
      'Veterinaria del barrio',
    );
  });

  test(
    'POST renueva ante 401; PATCH y ambas variantes de recomendación usan JWT',
    () async {
      int refreshes = 0, posts = 0;
      final api = HttpApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          if (r.url.path == '/api/auth/me') return response(usuarioJson());
          if (r.url.path == '/api/auth/refresh') {
            refreshes++;
            return response(sesionJson(token: 'access-2'));
          }
          if (r.url.path == '/api/publicaciones') {
            posts++;
            if (r.headers['Authorization'] == 'Bearer access-1') {
              return response({}, 401);
            }
            expect(r.method, 'POST');
            final j = jsonDecode(r.body) as Map;
            expect(j['fechaSuceso'], '2026-09-15');
            expect(j.containsKey('mascoteroId'), false);
            expect(j.containsKey('fotografias'), false);
            return response(publicacionJson(), 201);
          }
          expect(r.headers['Authorization'], 'Bearer access-2');
          if (r.url.path.endsWith('/resolver')) {
            expect(r.method, 'PATCH');
            expect(r.body, '');
            return response(publicacionJson(estado: 2));
          }
          expect(r.method, 'POST');
          final j = jsonDecode(r.body) as Map;
          expect(
            j.containsKey('nuevoPrestador') !=
                j.containsKey('prestadorServicioId'),
            true,
          );
          return response(recomendacionJson(), 201);
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
      final service = PublicacionServiceApi(api, auth);
      await service.crear(
        CrearPublicacionRequest(
          tipoPublicacion: 1,
          tipoMascota: 1,
          descripcion: 'Una descripción',
          fechaSuceso: DateTime(2026, 9, 15),
          localidadId: 'l1',
          zona: 'Plaza',
          informacionContacto: '123',
        ),
      );
      expect(refreshes, 1);
      expect(posts, 2);
      expect((await service.resolver('publicacion-1')).estado, 2);
      final recomendaciones = RecomendacionServiceApi(api, auth);
      await recomendaciones.crear(
        const CrearRecomendacionRequest(
          titulo: 'Buena atención',
          descripcion: 'Muy buena atención',
          prestadorServicioId: 'prestador-1',
        ),
      );
      await recomendaciones.crear(
        const CrearRecomendacionRequest(
          titulo: 'Buena atención',
          descripcion: 'Muy buena atención',
          nuevoPrestador: NuevoPrestadorRequest(
            nombre: 'Otro',
            rubroId: 'r1',
            localidadId: 'l1',
          ),
        ),
      );
    },
  );

  test('POST no se repite ante error de red, 400, 403 o 500', () async {
    for (final code in [0, 400, 403, 500]) {
      int sends = 0;
      final api = HttpApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/me')) return response(usuarioJson());
          sends++;
          if (code == 0) throw http.ClientException('sin red');
          return response({'title': 'Error de prueba'}, code);
        }),
      );
      final auth = AuthServiceApi(
        api,
        MemorySessionStorage()..value = sesionTexto(),
      );
      await auth.restaurar();
      await expectLater(
        auth.postProtegido('api/publicaciones', {}),
        throwsA(isA<ApiException>()),
      );
      expect(sends, 1);
      auth.dispose();
      api.close();
    }
  });
}
