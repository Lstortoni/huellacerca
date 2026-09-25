import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/pagina_dto.dart';
import 'package:huella_cerca/widgets/lista_paginada.dart';
import 'package:huella_cerca/core/network/api_exception.dart';
import 'package:huella_cerca/pages/mascotas_page.dart';
import 'package:huella_cerca/models/recomendacion_dto.dart';
import 'package:huella_cerca/models/notificacion_dto.dart';
import 'package:huella_cerca/pages/notificaciones_page.dart';
import 'package:huella_cerca/pages/perfil_page.dart';
import 'package:huella_cerca/pages/prestador_detalle_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/pages/publicar_mascota_page.dart';
import 'package:huella_cerca/pages/recomendaciones_page.dart';
import 'package:huella_cerca/pages/recomendar_servicio_page.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';

import 'support/comunidad_mocks.dart';
import 'support/notificaciones_mocks.dart';
import 'support/service_mocks.dart';

void main() {
  test('Fecha relativa compara solo el día', () {
    final ahora = DateTime(2026, 9, 22, 23, 50);
    expect(fechaRelativa(DateTime(2026, 9, 22), ahora: ahora), 'hoy');
    expect(fechaRelativa(DateTime(2026, 9, 21, 23), ahora: ahora), 'ayer');
    expect(fechaRelativa(DateTime(2026, 9, 15), ahora: ahora), 'hace 7 días');
    expect(fechaRelativa(DateTime(2026, 8, 1), ahora: ahora), 'el 1/8/2026');
  });
  testWidgets('Resultados: carga, error, reintento y vacío', (tester) async {
    final initial = Completer<PaginaDto<String>>();
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPaginada<String>(
            cargar: (_) {
              calls++;
              return calls == 1
                  ? initial.future
                  : Future.value(const PaginaDto([], 0, 1, 20));
            },
            itemBuilder: (s, _) => Text(s),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    initial.completeError(const ApiException('Sin conexión'));
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(
      find.text('No encontramos resultados con esos filtros.'),
      findsOneWidget,
    );
    expect(calls, 2);
  });
  testWidgets('Paginación solicita la siguiente página y permite volver', (
    tester,
  ) async {
    final pages = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPaginada<String>(
            cargar: (p) async {
              pages.add(p);
              return PaginaDto(['Resultado $p'], 21, p, 20);
            },
            itemBuilder: (s, _) => Text(s),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado 2'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Página siguiente',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Página anterior'));
    await tester.pumpAndSettle();
    expect(pages, [1, 2, 1]);
  });
  testWidgets(
    'Búsqueda y formulario se adaptan a pantalla angosta con texto grande',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = AuthServiceMock();
      addTearDown(auth.dispose);
      await auth.login(const LoginRequest('a@b.com', '12345678'));
      await tester.pumpWidget(
        MaterialApp(
          home: MascotasPage(
            auth: auth,
            service: PublicacionServiceMock(),
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Toby'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: RecomendarServicioPage(
            auth: auth,
            service: RecomendacionServiceMock(),
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: PublicarMascotaPage(
            auth: auth,
            service: PublicacionServiceMock(),
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Color predominante'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Información de contacto'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Formulario en modo edición: tipo fijo y ubicación precargada.
      await tester.pumpWidget(
        MaterialApp(
          home: PublicarMascotaPage(
            auth: auth,
            service: PublicacionServiceMock(),
            ubicacion: UbicacionServiceMock(),
            edicion: PublicacionDto.fromJson(publicacionJson()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Información de contacto'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Detalle visto por su autor: controles de foto y sección «Tu aviso».
      await tester.pumpWidget(
        MaterialApp(
          home: PublicacionDetallePage(
            id: 'publicacion-1',
            auth: auth,
            service: PublicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Marcar como resuelta'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final servicios = RecomendacionServiceMock();
      await servicios.crear(
        const CrearRecomendacionRequest(prestadorServicioId: 'prestador-1'),
      );
      await servicios.guardarAspectos('recomendacion-1', ['a1', 'a2']);
      await tester.pumpWidget(
        MaterialApp(
          home: RecomendacionesPage(
            auth: auth,
            service: servicios,
            ubicacion: UbicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Veterinaria del barrio'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: PrestadorDetallePage(
            id: 'prestador-1',
            auth: auth,
            service: servicios,
            permitirGestion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar aspectos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final notificaciones = NotificacionServiceMock()
        ..items = [NotificacionDto.fromJson(notificacionJson())]
        ..noLeidas = 1;
      addTearDown(notificaciones.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: NotificacionesPage(
            auth: auth,
            notificaciones: notificaciones,
            publicaciones: PublicacionServiceMock(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver mi aviso: Toby'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(MaterialApp(home: PerfilPage(auth: auth)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
