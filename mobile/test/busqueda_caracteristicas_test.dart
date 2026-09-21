import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/pages/mascotas_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';

import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';
import 'comunidad_pages_test.dart' show tapVisible;
import 'publicar_caracteristicas_test.dart' show elegir;

class DetalleConCaracteristicas extends PublicacionServiceMock {
  int tipo = 3;
  @override
  Future<PublicacionDto> detalle(String id) async => PublicacionDto.fromJson({
    ...publicacionJson(),
    'tipoPublicacion': tipo,
    'tamano': 2,
    'raza': 2,
  });
}

void main() {
  for (final tipo in [1, 2, 3, 4]) {
    testWidgets(
      'Detalle del aviso $tipo muestra valores informados sin sesión',
      (tester) async {
        final auth = AuthServiceMock();
        final service = DetalleConCaracteristicas()..tipo = tipo;
        addTearDown(auth.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: PublicacionDetallePage(
              id: 'p1',
              auth: auth,
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tamaño: Mediano'), findsOneWidget);
        expect(find.text('Raza: Mestizo'), findsOneWidget);
        expect(find.textContaining('Pelaje:'), findsNothing);
        expect(
          find.text(
            tipo == 4
                ? 'Características que busca'
                : 'Características de la mascota',
          ),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets('Fallo del catálogo no oculta contacto y admite reintento', (
    tester,
  ) async {
    final auth = AuthServiceMock();
    final service = DetalleConCaracteristicas()..falloCaracteristicas = true;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PublicacionDetallePage(id: 'p1', auth: auth, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2215550000'), findsOneWidget);
    service.falloCaracteristicas = false;
    await tapVisible(
      tester,
      find.text('No pudimos cargar las características. Reintentar'),
    );
    expect(find.text('Tamaño: Mediano'), findsOneWidget);
  });
  testWidgets(
    'Buscar envía filtros; quitar y cambiar animal no conserva filtros invisibles',
    (tester) async {
      final auth = AuthServiceMock();
      final service = PublicacionServiceMock();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MascotasPage(
            auth: auth,
            service: service,
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await elegir(tester, 'Tipo de mascota', 'Perro');
      await elegir(tester, 'Tamaño', 'Mediano');
      await elegir(tester, 'Raza', 'Mestizo');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buscar'));
      expect(service.filtros, {
        'estado': '1',
        'tipoMascota': '1',
        'tamano': '2',
        'raza': '2',
      });
      await tapVisible(tester, find.text('Quitar filtros de características'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buscar'));
      expect(service.filtros, {'estado': '1', 'tipoMascota': '1'});
      await elegir(tester, 'Raza', 'De raza');
      await elegir(tester, 'Tipo de mascota', 'Otro');
      expect(find.text('Raza'), findsNothing);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buscar'));
      expect(service.filtros, {'estado': '1', 'tipoMascota': '3'});
      await elegir(tester, 'Tamaño', 'Chico');
      await elegir(tester, 'Tipo de mascota', 'Todas');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buscar'));
      expect(service.filtros, {'estado': '1'});
    },
  );
}
