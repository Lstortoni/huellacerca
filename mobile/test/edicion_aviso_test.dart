import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';
import 'package:huella_cerca/services/implementations/publicacion_service_api.dart';

import 'comunidad_pages_test.dart' show tapVisible;
import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';

/// Sesión que registra los PUT/PATCH que arma el servicio real.
class AuthEdicion extends AuthServiceMock {
  final llamadas = <(String, Map<String, Object?>?)>[];
  @override
  Future<Object?> putProtegido(String path, Map<String, Object?> body) async {
    llamadas.add((path, body));
    return publicacionJson();
  }

  @override
  Future<Object?> patchProtegido(String path) async {
    llamadas.add((path, null));
    return publicacionJson();
  }
}

class AvisoEditado extends PublicacionServiceMock {
  @override
  Future<PublicacionDto> detalle(String id) async => PublicacionDto.fromJson({
    ...publicacionJson(),
    'fechaActualizacion': '2026-09-25T15:00:00Z',
  });
}

const _login = LoginRequest('a@b.com', '12345678');

EditarPublicacionRequest _request({int tipo = 1}) => EditarPublicacionRequest(
  tipoPublicacion: tipo,
  version: 'version-1',
  tipoMascota: 1,
  nombreMascota: 'Toby',
  descripcion: 'Perro marrón con collar azul.',
  fechaSuceso: DateTime(2026, 9, 15),
  localidadId: 'localidad-demo',
  zona: 'Plaza',
  informacionContacto: '2215550000',
  tamano: 2,
);

void main() {
  test(
    'El PUT envía la versión, no el tipo, y borra características con null',
    () {
      final json = _request().toJson();
      expect(json.containsKey('tipoPublicacion'), isFalse);
      expect(json['version'], 'version-1');
      expect(json['fechaSuceso'], '2026-09-15');
      expect(json['tamano'], 2);
      expect(json.containsKey('raza') && json['raza'] == null, isTrue);
      // Adopciones sin fecha; Busco adoptar sin nombre.
      expect(_request(tipo: 3).toJson()['fechaSuceso'], isNull);
      expect(_request(tipo: 4).toJson()['nombreMascota'], isNull);
    },
  );

  test('El servicio edita con PUT y reabre con PATCH', () async {
    final auth = AuthEdicion();
    addTearDown(auth.dispose);
    final service = PublicacionServiceApi(ApiClientMock(), auth);
    await service.editar('p1', _request());
    await service.reabrir('p1');
    expect(auth.llamadas[0].$1, 'api/publicaciones/p1');
    expect(auth.llamadas[0].$2!['version'], 'version-1');
    expect(auth.llamadas[1].$1, 'api/publicaciones/p1/reabrir');
  });

  group('Detalle y formulario de edición', () {
    late AuthServiceMock auth;
    late PublicacionServiceMock service;
    setUp(() async {
      auth = AuthServiceMock();
      service = PublicacionServiceMock();
      await auth.login(_login);
    });
    tearDown(() => auth.dispose());

    Future<void> abrirDetalle(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PublicacionDetallePage(
            id: 'publicacion-1',
            auth: auth,
            service: service,
          ),
          routes: {
            '/mascotas/editar': (context) => PublicarMascotaPage(
              auth: auth,
              service: service,
              ubicacion: UbicacionServiceMock(),
              edicion:
                  ModalRoute.of(context)!.settings.arguments! as PublicacionDto,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Precarga el aviso, deja fijo el tipo y guarda con la versión',
      (tester) async {
        await abrirDetalle(tester);
        expect(find.byTooltip('Editar aviso'), findsOneWidget); // Lápiz.
        await tapVisible(tester, find.text('Editar aviso'));
        expect(find.text('Tipo de aviso'), findsOneWidget);
        expect(find.text('Elegir foto'), findsNothing);
        expect(find.text('La Plata'), findsOneWidget); // Ubicación precargada.
        final descripcion = find.widgetWithText(TextFormField, 'Descripción');
        expect(
          tester.widget<TextFormField>(descripcion).controller!.text,
          'Perro marrón con collar azul.',
        );
        await tester.enterText(
          descripcion,
          'Perro marrón, collar azul y chapita.',
        );
        await tapVisible(tester, find.text('Guardar cambios'));
        expect(service.editada!.version, 'version-1');
        expect(service.editada!.tipoPublicacion, 1);
        expect(
          service.editada!.descripcion,
          'Perro marrón, collar azul y chapita.',
        );
        expect(service.editada!.localidadId, 'localidad-demo');
        expect(find.byType(PublicarMascotaPage), findsNothing);
        expect(find.byType(PublicacionDetallePage), findsOneWidget);
      },
    );

    testWidgets('Si el aviso cambió (409) avisa y vuelve al detalle', (
      tester,
    ) async {
      service.conflicto = true;
      await abrirDetalle(tester);
      await tapVisible(tester, find.byTooltip('Editar aviso'));
      await tapVisible(tester, find.text('Guardar cambios'));
      expect(find.text('El aviso cambió'), findsOneWidget);
      await tapVisible(tester, find.text('Volver al aviso'));
      expect(find.byType(PublicarMascotaPage), findsNothing);
      expect(find.byType(PublicacionDetallePage), findsOneWidget);
    });

    testWidgets('Salir con cambios sin guardar pide confirmación', (
      tester,
    ) async {
      await abrirDetalle(tester);
      await tapVisible(tester, find.text('Editar aviso'));
      await tester.pageBack(); // Sin cambios: sale directo.
      await tester.pumpAndSettle();
      expect(find.byType(PublicarMascotaPage), findsNothing);
      await tapVisible(tester, find.text('Editar aviso'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Zona aproximada'),
        'Plaza Moreno',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicarMascotaPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicarMascotaPage), findsNothing);
      expect(service.editada, isNull);
    });

    testWidgets('Un aviso resuelto se puede reabrir y editar', (tester) async {
      service.estado = 2;
      await abrirDetalle(tester);
      expect(find.text('Editar aviso'), findsOneWidget);
      await tapVisible(tester, find.text('Reabrir aviso'));
      await tester.tap(find.text('Reabrir'));
      await tester.pumpAndSettle();
      expect(service.reaperturas, 1);
      expect(find.text('Marcar como resuelta'), findsOneWidget);
      expect(find.text('Este caso fue resuelto'), findsNothing);
    });

    testWidgets('Otra cuenta no ve editar ni reabrir', (tester) async {
      service.autorId = 'otro';
      await abrirDetalle(tester);
      expect(find.byTooltip('Editar aviso'), findsNothing);
      expect(find.text('Editar aviso'), findsNothing);
      expect(find.text('Reabrir aviso'), findsNothing);
    });

    testWidgets('Muestra la fecha de la última edición', (tester) async {
      service = AvisoEditado();
      await abrirDetalle(tester);
      expect(find.textContaining('Editado el 25/9/2026'), findsOneWidget);
    });
  });
}
