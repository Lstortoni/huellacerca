import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/pages/mascotas_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';

import 'support/comunidad_mocks.dart';
import 'support/service_mocks.dart';
import 'comunidad_pages_test.dart' show tapVisible;

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

/// Valor informado de una característica en el detalle del aviso.
Finder dato(String etiqueta, String valor) => find.descendant(
  of: find.byKey(ValueKey('caracteristica:$etiqueta')),
  matching: find.text(valor),
);

void main() {
  for (final soloMias in [false, true]) {
    testWidgets('Filtro de autor con sesión, soloMias=$soloMias', (
      tester,
    ) async {
      final auth = AuthServiceMock();
      await auth.login(const LoginRequest('a@b.com', '12345678'));
      addTearDown(auth.dispose);
      final service = PublicacionServiceMock();
      await tester.pumpWidget(
        MaterialApp(
          home: MascotasPage(
            auth: auth,
            service: service,
            ubicacion: UbicacionServiceMock(),
            soloMias: soloMias,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final esperados = <String, String>{
        if (!soloMias) 'estado': '1',
        (soloMias ? 'mascoteroId' : 'excluirMascoteroId'):
            auth.usuario!.mascotero.id,
      };
      expect(service.filtros, esperados);
      await tapVisible(tester, find.text('Perro'));
      expect(service.filtros, {...esperados, 'tipoMascota': '1'});
    });
  }
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
        expect(dato('Tamaño', 'Mediano'), findsOneWidget);
        expect(dato('Raza', 'Mestizo'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('caracteristica:Pelaje')),
          findsNothing,
        );
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
    expect(dato('Tamaño', 'Mediano'), findsOneWidget);
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
      final aplicar = find.widgetWithText(FilledButton, 'Aplicar filtros');
      await tapVisible(tester, find.text('Perro'));
      expect(service.filtros, {'estado': '1', 'tipoMascota': '1'});
      await tapVisible(tester, find.text('Filtros'));
      await tapVisible(tester, find.text('Mediano'));
      await tapVisible(tester, find.text('Mestizo'));
      await tapVisible(tester, aplicar);
      expect(service.filtros, {
        'estado': '1',
        'tipoMascota': '1',
        'tamano': '2',
        'raza': '2',
      });
      // Los filtros aplicados se ven como chips que se pueden quitar.
      expect(find.widgetWithText(InputChip, 'Mediano'), findsOneWidget);
      await tapVisible(tester, find.text('Filtros'));
      await tapVisible(tester, find.text('Quitar filtros de características'));
      await tapVisible(tester, aplicar);
      expect(service.filtros, {'estado': '1', 'tipoMascota': '1'});
      await tapVisible(tester, find.text('Filtros'));
      await tapVisible(tester, find.text('De raza'));
      await tapVisible(tester, find.text('Otro'));
      expect(find.text('Raza'), findsNothing);
      expect(service.filtros, {'estado': '1', 'tipoMascota': '3'});
      await tapVisible(tester, find.text('Filtros'));
      await tapVisible(tester, find.text('Chico'));
      await tapVisible(tester, find.text('Otro'));
      expect(service.filtros, {'estado': '1'});
    },
  );
}
