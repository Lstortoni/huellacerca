import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/pages/mascotas_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';
import 'package:huella_cerca/pages/recomendar_servicio_page.dart';
import 'package:huella_cerca/pages/recomendacion_detalle_page.dart';

import 'support/service_mocks.dart';
import 'support/comunidad_mocks.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> elegirLocalidad(WidgetTester tester) async {
  await tapVisible(
    tester,
    find.widgetWithText(DropdownButtonFormField<String>, 'Provincia'),
  );
  await tester.tap(find.text('Provincia simulada').last);
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('Elegir localidad'));
  await tester.tap(find.text('Localidad simulada'));
  await tester.pumpAndSettle();
}

void main() {
  late AuthServiceMock auth;
  late PublicacionServiceMock mascotas;
  late RecomendacionServiceMock recomendaciones;
  setUp(() {
    auth = AuthServiceMock();
    mascotas = PublicacionServiceMock();
    recomendaciones = RecomendacionServiceMock();
  });
  tearDown(() => auth.dispose());
  Future<void> login() => auth.login(const LoginRequest('a@b.com', '12345678'));

  testWidgets(
    'Búsqueda pública abre detalle y no ofrece resolver a visitantes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MascotasPage(
            auth: auth,
            service: mascotas,
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Toby · Perdida'));
      expect(find.text('2215550000'), findsOneWidget);
      expect(find.text('Marcar como resuelta'), findsNothing);
    },
  );
  testWidgets('Autor resuelve con confirmación y el estado cambia', (
    tester,
  ) async {
    await login();
    await tester.pumpWidget(
      MaterialApp(
        home: PublicacionDetallePage(
          id: 'publicacion-1',
          auth: auth,
          service: mascotas,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Marcar como resuelta'));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(mascotas.resoluciones, 1);
    expect(find.text('Perdida · Perro · Resuelta'), findsOneWidget);
    expect(find.text('Marcar como resuelta'), findsNothing);
  });
  testWidgets('Otro mascotero no ve acción para resolver', (tester) async {
    await login();
    mascotas.autorId = 'otro';
    await tester.pumpWidget(
      MaterialApp(
        home: PublicacionDetallePage(
          id: 'publicacion-1',
          auth: auth,
          service: mascotas,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Marcar como resuelta'), findsNothing);
  });
  testWidgets(
    'Publicación valida y envía localidad, fecha y descripción sin fotos',
    (tester) async {
      await login();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicarMascotaPage(
            auth: auth,
            service: mascotas,
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Publicar'));
      expect(mascotas.creada, isNull);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción'),
        'Perro marrón con collar azul',
      );
      await tapVisible(tester, find.text('Elegir fecha del suceso'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await elegirLocalidad(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Zona aproximada'),
        'Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Información de contacto'),
        '123456',
      );
      await tapVisible(tester, find.text('Publicar'));
      expect(mascotas.creada!.localidadId, 'localidad-demo');
      expect(mascotas.creada!.nombreMascota, isNull);
      expect(find.byType(PublicacionDetallePage), findsOneWidget);
    },
  );
  for (final nuevo in [false, true]) {
    testWidgets(
      'Recomienda ${nuevo ? 'prestador nuevo' : 'prestador existente'} después de buscar similares',
      (tester) async {
        await login();
        await tester.pumpWidget(
          MaterialApp(
            home: RecomendarServicioPage(
              auth: auth,
              service: recomendaciones,
              ubicacion: UbicacionServiceMock(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre del servicio o negocio'),
          'Veterinaria',
        );
        await tapVisible(
          tester,
          find.widgetWithText(DropdownButtonFormField<String>, 'Rubro'),
        );
        await tester.tap(find.text('Veterinaria').last);
        await tester.pumpAndSettle();
        await elegirLocalidad(tester);
        await tapVisible(tester, find.text('Buscar similares'));
        await tapVisible(
          tester,
          find.text(
            nuevo
                ? 'Es otro servicio: crear uno nuevo'
                : 'Veterinaria del barrio',
          ),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título de tu recomendación'),
          'Buena atención',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contá tu experiencia'),
          'Nos atendieron muy bien.',
        );
        await tapVisible(tester, find.text('Publicar recomendación'));
        expect(recomendaciones.creada, isNotNull);
        expect(recomendaciones.creada!.nuevoPrestador != null, nuevo);
        expect(
          recomendaciones.creada!.prestadorServicioId,
          nuevo ? null : 'prestador-1',
        );
        expect(find.byType(RecomendacionDetallePage), findsOneWidget);
      },
    );
  }
  testWidgets('Cambiar nombre invalida la elección del prestador anterior', (
    tester,
  ) async {
    await login();
    await tester.pumpWidget(
      MaterialApp(
        home: RecomendarServicioPage(
          auth: auth,
          service: recomendaciones,
          ubicacion: UbicacionServiceMock(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del servicio o negocio'),
      'Veterinaria',
    );
    await tapVisible(
      tester,
      find.widgetWithText(DropdownButtonFormField<String>, 'Rubro'),
    );
    await tester.tap(find.text('Veterinaria').last);
    await tester.pumpAndSettle();
    await elegirLocalidad(tester);
    await tapVisible(tester, find.text('Buscar similares'));
    await tapVisible(tester, find.text('Veterinaria del barrio'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del servicio o negocio'),
      'Peluquería',
    );
    await tester.pumpAndSettle();
    expect(find.text('Publicar recomendación'), findsNothing);
  });
  testWidgets('Formularios requieren sesión', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicarMascotaPage(
          auth: auth,
          service: mascotas,
          ubicacion: UbicacionServiceMock(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ingresá para continuar.'), findsOneWidget);
    expect(find.text('Publicar'), findsNothing);
  });
}
