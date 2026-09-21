import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';

import 'support/auth_fakes.dart';
import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';
import 'comunidad_pages_test.dart' show tapVisible, elegirLocalidad;

Future<void> elegir(WidgetTester tester, String campo, String opcion) async {
  await tapVisible(
    tester,
    find.widgetWithText(DropdownButtonFormField<int>, campo),
  );
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

Future<void> completar(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Descripción'),
    'Mascota de tamaño mediano y pelaje corto.',
  );
  await elegirLocalidad(tester);
  final zona = find.widgetWithText(TextFormField, 'Zona aproximada');
  if (zona.evaluate().isNotEmpty) await tester.enterText(zona, 'Centro');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Información de contacto'),
    '2215551234',
  );
}

class OpcionesDemoradas extends PublicacionServiceMock {
  final perro = Completer<List<CaracteristicaMascotaDto>>();
  @override
  Future<List<CaracteristicaMascotaDto>> caracteristicas(int tipoMascota) =>
      tipoMascota == 1 ? perro.future : super.caracteristicas(tipoMascota);
}

void main() {
  test('DTO acepta avisos anteriores; catálogo público y POST con características usan el contrato HTTP', () async {
    expect(PublicacionDto.fromJson(publicacionJson()).raza, isNull);
    final api = HttpApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        Object body;
        if (r.url.path.endsWith('/me')) {
          body = usuarioJson();
        } else if (r.url.path.endsWith('/caracteristicas')) {
          expect(r.method, 'GET');
          expect(r.url.queryParameters, {'tipoMascota': '2'});
          expect(r.headers['Authorization'], isNull);
          body = caracteristicasJson(2);
        } else {
          expect(r.method, 'POST');
          expect(r.headers['Authorization'], 'Bearer access-1');
          final j = jsonDecode(r.body) as Map;
          expect(j['tamano'], 2);
          expect(j['raza'], 2);
          expect(j.containsKey('colorOjos'), false);
          body = {...publicacionJson(), 'tamano': 2, 'raza': 2};
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
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
    expect((await service.caracteristicas(2)).length, 5);
    final p = await service.crear(
      const CrearPublicacionRequest(
        tipoPublicacion: 3,
        tipoMascota: 2,
        descripcion: 'Descripción',
        localidadId: 'l1',
        zona: 'Centro',
        informacionContacto: '123',
        tamano: 2,
        raza: 2,
      ),
    );
    expect(p.tamano, 2);
    expect(p.raza, 2);
    expect(p.colorOjos, isNull);
  });

  for (final tipo in tiposPublicacion.entries) {
    testWidgets('Publicar ${tipo.value} envía características opcionales', (
      tester,
    ) async {
      final auth = AuthServiceMock();
      final service = PublicacionServiceMock();
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
      await elegir(tester, 'Tamaño', 'Mediano');
      await elegir(tester, 'Raza', 'Mestizo');
      await elegir(tester, 'Pelaje', 'Corto');
      if (tipo.key == 4) {
        expect(
          find.text('Características que buscás (opcionales)'),
          findsOneWidget,
        );
      }
      await completar(tester);
      if (tipo.key <= 2) {
        await tapVisible(tester, find.text('Elegir fecha del suceso'));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      await tapVisible(tester, find.text('Publicar'));
      expect(service.creada!.tipoPublicacion, tipo.key);
      expect(service.creada!.tamano, 2);
      expect(service.creada!.raza, 2);
      expect(service.creada!.pelaje, 1);
      expect(service.creada!.colorOjos, isNull);
      expect(service.creada!.fechaSuceso != null, tipo.key <= 2);
    });
  }

  testWidgets('Cambiar de especie limpia valores y Sin indicar no envía cero', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = PublicacionServiceMock();
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
    await elegir(tester, '¿Qué querés publicar?', 'Busco adoptar');
    await elegir(tester, 'Raza', 'De raza');
    await elegir(tester, 'Tipo de mascota', 'Otro');
    expect(find.text('Raza'), findsNothing);
    expect(find.text('Pelaje'), findsNothing);
    await elegir(tester, 'Tamaño', 'Chico');
    await elegir(tester, 'Tamaño', 'Sin indicar');
    await completar(tester);
    await tapVisible(tester, find.text('Publicar'));
    expect(service.creada!.tipoMascota, 3);
    for (final campo in [
      'tamano',
      'raza',
      'pelaje',
      'colorPredominante',
      'colorOjos',
    ]) {
      expect(service.creada!.toJson().containsKey(campo), false);
    }
  });

  testWidgets(
    'Error del catálogo permite reintentar y publicar sin características',
    (tester) async {
      final auth = AuthServiceMock();
      final service = PublicacionServiceMock()..falloCaracteristicas = true;
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
      expect(find.text('Reintentar características'), findsOneWidget);
      service.falloCaracteristicas = false;
      await tapVisible(tester, find.text('Reintentar características'));
      expect(find.text('Raza'), findsOneWidget);
      service.falloCaracteristicas = true;
      await elegir(tester, 'Tipo de mascota', 'Otro');
      expect(find.text('Reintentar características'), findsOneWidget);
      await elegir(tester, '¿Qué querés publicar?', 'Busco adoptar');
      await completar(tester);
      await tapVisible(tester, find.text('Publicar'));
      expect(service.creada!.tamano, isNull);
    },
  );

  testWidgets(
    'Una respuesta tardía de perro no reemplaza opciones de otro animal',
    (tester) async {
      final auth = AuthServiceMock();
      final service = OpcionesDemoradas();
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
      await tester.pump();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Tipo de mascota'),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Otro').last);
      await tester.pumpAndSettle();
      service.perro.complete(
        caracteristicasJson(1).map(CaracteristicaMascotaDto.fromJson).toList(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Raza'), findsNothing);
      expect(find.text('Tamaño'), findsOneWidget);
    },
  );
}
