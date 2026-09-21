import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/core/network/api_exception.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/foto_seleccionada.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';

import 'support/auth_fakes.dart';
import 'support/service_mocks.dart';
import 'support/comunidad_mocks.dart';
import 'publicar_caracteristicas_test.dart' show completar, elegir;
import 'comunidad_pages_test.dart' show tapVisible;

final foto = FotoSeleccionada(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
  ),
);

class FotosMock extends PublicacionServiceMock {
  int subidas = 0, creaciones = 0;
  bool falla = true;
  @override
  Future<FotoSeleccionada?> elegirFoto() async => foto;
  @override
  Future<PublicacionDto> crear(CrearPublicacionRequest request) async {
    creaciones++;
    return super.crear(request);
  }

  @override
  Future<void> subirFoto(String id, FotoSeleccionada foto) async {
    subidas++;
    if (falla) throw const ApiException('R2 no disponible');
  }
}

void main() {
  test(
    'Multipart reintenta 401 con un request nuevo y conserva los bytes',
    () async {
      var subidas = 0;
      final api = HttpApiClient(
        baseUrl: 'http://localhost:5080/',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/me')) {
            return http.Response(jsonEncode(usuarioJson()), 200);
          }
          if (r.url.path.endsWith('/refresh')) {
            return http.Response(
              jsonEncode(sesionJson(token: 'access-2')),
              200,
            );
          }
          expect(r.method, 'PUT');
          expect(r.url.path, '/api/publicaciones/p1/foto');
          expect(r.headers['content-type'], startsWith('multipart/form-data;'));
          expect(latin1.decode(r.bodyBytes), contains('name="archivo"'));
          expect(
            latin1.decode(r.bodyBytes),
            contains(latin1.decode(foto.bytes)),
          );
          subidas++;
          if (subidas == 1) return http.Response('{}', 401);
          expect(r.headers['Authorization'], 'Bearer access-2');
          return http.Response(
            '{"id":"foto-1","url":"api/publicaciones/p1/foto?v=1"}',
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
      final service = PublicacionServiceApi(api, auth);
      await service.subirFoto('p1', foto);
      expect(subidas, 2);
      expect(
        service.urlFoto('api/publicaciones/p1/foto?v=1'),
        'http://localhost:5080/api/publicaciones/p1/foto?v=1',
      );
    },
  );
  test('DTO acepta foto opcional y no necesita ObjectKey ni secretos', () {
    expect(PublicacionDto.fromJson(publicacionJson()).fotoUrl, null);
    expect(
      PublicacionDto.fromJson({
        ...publicacionJson(),
        'foto': {'id': 'f1', 'url': 'api/publicaciones/p1/foto?v=f1'},
      }).fotoUrl,
      'api/publicaciones/p1/foto?v=f1',
    );
  });
  testWidgets(
    'Una subida fallida conserva el aviso y reintenta sin duplicarlo',
    (tester) async {
      final auth = AuthServiceMock();
      final service = FotosMock();
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
      await tapVisible(tester, find.text('Elegir foto'));
      await elegir(tester, '¿Qué querés publicar?', 'Doy en adopción');
      await completar(tester);
      await tapVisible(tester, find.text('Publicar'));
      expect(service.creaciones, 1);
      expect(service.subidas, 1);
      expect(find.text('R2 no disponible'), findsOneWidget);
      service.falla = false;
      await tapVisible(tester, find.text('Reintentar foto'));
      expect(service.subidas, 2);
      expect(service.creaciones, 1);
      expect(find.text('R2 no disponible'), findsNothing);
    },
  );
}
