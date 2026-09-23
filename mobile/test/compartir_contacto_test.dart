import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/core/util/contacto.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/models/recomendacion_dto.dart';
import 'package:huella_cerca/pages/prestador_detalle_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/services/contracts/acciones_externas.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';
import 'package:huella_cerca/services/implementations/recomendacion_service_api.dart';

import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';
import 'comunidad_pages_test.dart' show tapVisible;

class AccionesFake implements AccionesExternas {
  String? texto, urlImagen;
  final abiertos = <Uri>[];
  @override
  Future<void> compartir(String texto, {String? urlImagen}) async {
    this.texto = texto;
    this.urlImagen = urlImagen;
  }

  @override
  Future<bool> abrir(Uri uri) async {
    abiertos.add(uri);
    return true;
  }
}

class PrestadorConTelefono extends RecomendacionServiceMock {
  @override
  Future<PrestadorDto> detalle(String id) async =>
      PrestadorDto.fromJson({...prestadorJson(), 'telefono': '221 555-1234'});
}

void main() {
  test('Detecta teléfonos dentro de un contacto libre', () {
    expect(telefonoEn('Llamar al 221 555-0000 de tarde'), '2215550000');
    expect(telefonoEn('WhatsApp: +54 9 11 1234-5678'), '+5491112345678');
    expect(telefonoEn('Escribime a ana@example.com'), isNull);
    expect(telefonoEn('Zona 123'), isNull); // Muy corto para ser teléfono.
  });

  test('WhatsApp usa formato de celular argentino', () {
    expect(numeroWhatsApp('2215550000'), '5492215550000');
    expect(numeroWhatsApp('02215550000'), '5492215550000');
    expect(numeroWhatsApp('221 15 555-0000'), '5492215550000');
    expect(numeroWhatsApp('11 15 1234 5678'), '5491112345678');
    expect(numeroWhatsApp('+5491112345678'), '5491112345678');
    final uri = uriWhatsApp('2215550000', 'Hola, ¿sigue?');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/5492215550000');
    expect(uri.queryParameters['text'], 'Hola, ¿sigue?');
    expect(uriLlamada('2215550000').toString(), 'tel:2215550000');
  });

  test('Texto para compartir resume el aviso', () {
    final texto = PublicacionDto.fromJson(publicacionJson()).textoParaCompartir;
    expect(texto, startsWith('🔍 MASCOTA PERDIDA: Toby (Perro)'));
    expect(texto, contains('📍 La Plata, Buenos Aires · Plaza'));
    expect(texto, contains('Perro marrón con collar azul.'));
    expect(texto, contains('📞 Contacto: 2215550000'));
  });

  test('Los servicios delegan en acciones externas con URL absoluta', () async {
    final api = HttpApiClient(
      baseUrl: 'http://localhost:5080/',
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    final auth = AuthServiceMock();
    addTearDown(() {
      api.close();
      auth.dispose();
    });
    final acciones = AccionesFake();
    final service = PublicacionServiceApi(api, auth, null, acciones);
    await service.compartir(
      PublicacionDto.fromJson({
        ...publicacionJson(),
        'foto': {'id': 'f1', 'url': 'api/publicaciones/p1/foto?v=f1'},
      }),
    );
    expect(acciones.texto, contains('Toby'));
    expect(
      acciones.urlImagen,
      'http://localhost:5080/api/publicaciones/p1/foto?v=f1',
    );
    expect(await service.llamar('2215550000'), isTrue);
    expect(
      await RecomendacionServiceApi(
        api,
        auth,
        acciones,
      ).escribirPorWhatsApp('2215550000', 'Hola'),
      isTrue,
    );
    expect(acciones.abiertos.map((u) => u.scheme), ['tel', 'https']);
    // Sin acciones configuradas no falla: informa que no pudo abrir.
    expect(await PublicacionServiceApi(api, auth).llamar('1'), isFalse);
  });

  testWidgets('Detalle comparte el aviso y abre llamada o WhatsApp', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = PublicacionServiceMock();
    addTearDown(auth.dispose);
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
    await tapVisible(tester, find.text('Compartir aviso'));
    expect(service.compartida!.id, 'publicacion-1');
    await tapVisible(tester, find.text('Llamar'));
    await tapVisible(tester, find.text('WhatsApp'));
    expect(service.abiertos, ['tel:2215550000', 'wa:2215550000']);
    service.hayApp = false;
    await tapVisible(tester, find.text('Llamar'));
    expect(find.textContaining('No encontramos una app'), findsOneWidget);
  });

  testWidgets('El autor puede compartir pero no se llama a sí mismo', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = PublicacionServiceMock(); // Autor: mascotero-1.
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
    expect(find.text('Compartir aviso'), findsOneWidget);
    expect(find.text('Así te van a contactar'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
  });

  testWidgets('Aviso resuelto no ofrece compartir', (tester) async {
    final auth = AuthServiceMock();
    final service = PublicacionServiceMock()..estado = 2;
    addTearDown(auth.dispose);
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
    expect(find.text('Compartir aviso'), findsNothing);
  });

  testWidgets('Prestador con teléfono ofrece Llamar y WhatsApp', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = PrestadorConTelefono();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorDetallePage(
          id: 'prestador-1',
          auth: auth,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('WhatsApp'));
    expect(service.abiertos, ['wa:2215551234']);
  });
}
