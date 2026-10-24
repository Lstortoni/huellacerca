import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:huella_cerca/app.dart';
import 'package:huella_cerca/core/config/api_config.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/core/storage/secure_session_storage.dart';
import 'package:huella_cerca/core/di/service_registration.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/services/implementations/auth_service_api.dart';
import 'package:huella_cerca/services/implementations/ubicacion_service_api.dart';

/// Requiere API local y catálogo importado. Crea una cuenta hc-mobile-test-*.
/// Usa una clave de almacenamiento separada para no tocar la sesión del usuario.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'API local: registro, restauración segura, perfil, logout y login',
    (tester) async {
      final uri = Uri.parse(ApiConfig.baseUrl);
      expect(
        ['10.0.2.2', '127.0.0.1', 'localhost'],
        contains(uri.host),
        reason: 'Esta prueba solo debe ejecutarse contra la API local.',
      );
      expect(uri.port, 5080);
      final storage = SecureSessionStorage(
        key: 'huella_cerca_integration_test',
      );
      await storage.clear();
      final api = HttpApiClient(baseUrl: ApiConfig.baseUrl);
      final auth = AuthServiceApi(api, storage);
      final ubicacion = UbicacionServiceApi(api);
      final email =
          'hc-mobile-test-${DateTime.now().microsecondsSinceEpoch}@example.com';
      const password = 'PruebaMobile2026!';
      try {
        await auth.restaurar();
        final provincias = await ubicacion.getProvincias();
        final localidades = await ubicacion.getLocalidades(
          provinciaId: provincias.first.id,
        );
        await auth.registrar(
          RegisterRequest(
            nombre: 'Prueba',
            apellido: 'Flutter',
            email: email,
            password: password,
            passwordConfirm: password,
            localidadId: localidades.items.first.id,
          ),
        );
        expect(auth.autenticado, isTrue);
        expect(await storage.read(), isNot(contains(password)));

        // La app usa una nueva instancia de AuthService y recupera el almacenamiento nativo.
        configurarServicios(sessionStorage: storage);
        await tester.pumpWidget(const HuellaCercaApp());
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 45),
        );
        await tester.tap(find.byTooltip('Cuenta'));
        await tester.pumpAndSettle();
        expect(find.text('Mi perfil'), findsOneWidget);
        await tester.tap(find.text('Mi perfil'));
        await tester.pumpAndSettle();
        expect(find.text(email), findsOneWidget);
        await tester.tap(find.byTooltip('Cuenta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();
        expect(await storage.read(), isNull);

        await tester.tap(find.byTooltip('Cuenta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ingresar').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), email);
        await tester.enterText(find.byType(TextFormField).at(1), password);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Ingresar'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Cuenta'));
        await tester.pumpAndSettle();
        expect(find.text('Mi perfil'), findsOneWidget);
        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();
        expect(await storage.read(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await getIt.reset();
        await auth.logout();
        await storage.clear();
        auth.dispose();
        api.close();
      }
    },
  );
}
