import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fakes.dart';

import 'package:huella_cerca/app.dart';
import 'package:huella_cerca/core/di/service_registration.dart';
import 'package:huella_cerca/core/network/api_client.dart';
import 'package:huella_cerca/services/contracts/auth_service.dart';
import 'package:huella_cerca/services/contracts/ubicacion_service.dart';

import 'support/service_mocks.dart';

void main() {
  test('Registro real reutiliza contratos y permite configurar una ejecución nueva', () async {
    configurarServicios(
      httpClient: MockClient((_) async => http.Response('Healthy', 200)),
      sessionStorage: MemorySessionStorage(),
    );
    addTearDown(() => getIt.reset());
    final auth = getIt<AuthService>();
    expect(identical(auth, getIt<AuthService>()), isTrue);
    expect(identical(getIt<ApiClient>(), getIt<ApiClient>()), isTrue);
    expect(
      identical(getIt<UbicacionService>(), getIt<UbicacionService>()),
      isTrue,
    );
    await auth.restaurar();
    expect(auth.autenticado, isFalse);
    await getIt.reset();
    expect(getIt.isRegistered<AuthService>(), isFalse);
    configurarServicios(sessionStorage: MemorySessionStorage());
    expect(identical(auth, getIt<AuthService>()), isFalse);
  });
  testWidgets('Mismas páginas y barra con servicios intercambiados, sin HTTP', (
    tester,
  ) async {
    final api = ApiClientMock();
    final auth = AuthServiceMock();
    final ubicacion = UbicacionServiceMock();
    getIt.registerSingleton<ApiClient>(api, dispose: (value) => value.close());
    getIt.registerSingleton<AuthService>(
      auth,
      dispose: (value) => value.dispose(),
    );
    getIt.registerSingleton<UbicacionService>(ubicacion);
    addTearDown(() => getIt.reset());
    await tester.pumpWidget(const HuellaCercaApp());
    await tester.pumpAndSettle();
    expect(identical(getIt<AuthService>(), getIt<AuthService>()), isTrue);
    expect(auth.restores, 1);
    expect(ubicacion.consultas, 0);
    expect(find.text('Buscar mascotas'), findsOneWidget);
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingresar').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'prueba@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
    expect(auth.logins, 1);
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Prueba'), findsOneWidget);
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(auth.autenticado, isFalse);
    expect(auth.restores, 1);
    await tester.pumpWidget(const SizedBox());
    await getIt.reset();
    await getIt.reset(); // Un segundo reset no duplica cierres.
    expect(auth.disposals, 1);
    expect(api.closes, 1);
  });
}
