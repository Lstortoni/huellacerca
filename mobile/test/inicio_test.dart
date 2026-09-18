import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/app.dart';
import 'package:huella_cerca/core/di/service_registration.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/services/contracts/auth_service.dart';
import 'package:huella_cerca/widgets/tarjeta_inicio.dart';

import 'support/service_mocks.dart';
import 'support/comunidad_mocks.dart';

import 'package:huella_cerca/services/contracts/ubicacion_service.dart';
import 'package:huella_cerca/services/contracts/publicacion_service.dart';
import 'package:huella_cerca/services/contracts/recomendacion_service.dart';

class _AuthRestaurando extends AuthServiceMock {
  final ready = Completer<void>();
  bool _restaurando = true;
  @override
  bool get restaurando => _restaurando;
  @override
  Future<void> restaurar() async {
    await ready.future;
    _restaurando = false;
    notifyListeners();
  }
}

void main() {
  late AuthServiceMock auth;
  setUp(() {
    auth = AuthServiceMock();
    getIt.registerSingleton<AuthService>(auth, dispose: (a) => a.dispose());
  });
  tearDown(() => getIt.reset());

  testWidgets('Inicio público funciona sin registrar HTTP ni ubicación', (
    tester,
  ) async {
    await tester.pumpWidget(const HuellaCercaApp());
    await tester.pumpAndSettle();
    expect(find.byType(TarjetaInicio), findsNWidgets(2));
    expect(find.text('Buscar mascotas'), findsOneWidget);
    expect(find.text('Servicios recomendados'), findsOneWidget);
    expect(find.text('Publicar un aviso'), findsNothing);
    expect(find.text('Mis publicaciones'), findsNothing);
    expect(find.text('Recomendar un servicio'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Ingresar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Registrarse'), findsOneWidget);
  });

  testWidgets('La misma pantalla reacciona al login y logout', (tester) async {
    await tester.pumpWidget(const HuellaCercaApp());
    await tester.pumpAndSettle();
    await auth.login(const LoginRequest('prueba@example.com', '12345678'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.byType(TarjetaInicio), findsNWidgets(5));
    expect(find.widgetWithText(FilledButton, 'Ingresar'), findsNothing);
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsNothing);
    expect(find.byType(TarjetaInicio), findsNWidgets(2));
  });

  testWidgets(
    'Las cinco tarjetas abren las pantallas conectadas y permiten volver',
    (tester) async {
      getIt.registerSingleton<UbicacionService>(UbicacionServiceMock());
      getIt.registerSingleton<PublicacionService>(PublicacionServiceMock());
      getIt.registerSingleton<RecomendacionService>(RecomendacionServiceMock());
      await tester.pumpWidget(const HuellaCercaApp());
      await tester.pumpAndSettle();
      for (final title in [
        'Buscar mascotas',
        'Servicios recomendados',
        'Publicar un aviso',
        'Mis publicaciones',
        'Recomendar un servicio',
      ]) {
        if (title == 'Publicar un aviso') {
          await auth.login(
            const LoginRequest('prueba@example.com', '12345678'),
          );
          await tester.pumpAndSettle();
        }
        await tester.scrollUntilVisible(
          find.text(title),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.text('Próximamente'), findsNothing);
        expect(find.text(title), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.byType(TarjetaInicio),
          findsNWidgets(auth.autenticado ? 5 : 2),
        );
      }
    },
  );

  testWidgets(
    'Restaurar sesión no bloquea búsquedas ni muestra login transitoriamente',
    (tester) async {
      await getIt.reset();
      final pending = _AuthRestaurando();
      getIt.registerSingleton<AuthService>(
        pending,
        dispose: (a) => a.dispose(),
      );
      await tester.pumpWidget(const HuellaCercaApp());
      await tester.pump();
      expect(find.text('Recuperando tu sesión…'), findsOneWidget);
      expect(find.text('Buscar mascotas'), findsOneWidget);
      expect(find.text('Ingresar'), findsNothing);
      pending.ready.complete();
      await tester.pumpAndSettle();
      expect(find.text('Recuperando tu sesión…'), findsNothing);
      expect(find.text('Ingresar'), findsOneWidget);
    },
  );

  testWidgets('Inicio con sesión admite pantalla angosta y texto grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await auth.login(const LoginRequest('prueba@example.com', '12345678'));
    await tester.pumpWidget(const HuellaCercaApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Recomendar un servicio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
