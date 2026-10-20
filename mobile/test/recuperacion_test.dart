import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/pages/login_page.dart';
import 'package:huella_cerca/pages/recuperar_password_page.dart';
import 'package:huella_cerca/services/implementations/recuperacion_service_api.dart';

import 'support/service_mocks.dart';

Future<void> tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Login → email → código → contraseña → login, sin iniciar sesión',
    (tester) async {
      final pedidos = <http.Request>[];
      final api = HttpApiClient(
        baseUrl: 'https://api.example.invalid',
        client: MockClient((r) async {
          pedidos.add(r);
          expect(r.headers.containsKey('Authorization'), false);
          switch (r.url.path) {
            case '/api/auth/forgot-password':
              expect(jsonDecode(r.body), {'email': 'ana@example.com'});
              return http.Response('{"reintentarEnSegundos":60}', 202);
            case '/api/auth/verify-reset-code':
              expect(jsonDecode(r.body), {
                'email': 'ana@example.com',
                'codigo': '012345',
              });
              return http.Response(
                jsonEncode({
                  'resetToken': 'permiso-temporal',
                  'expiresAtUtc': DateTime.now()
                      .toUtc()
                      .add(const Duration(minutes: 10))
                      .toIso8601String(),
                }),
                200,
              );
            case '/api/auth/reset-password':
              expect(jsonDecode(r.body), {
                'resetToken': 'permiso-temporal',
                'password': 'Nueva-123',
                'passwordConfirm': 'Nueva-123',
              });
              return http.Response('{}', 200);
          }
          throw StateError('Llamado inesperado');
        }),
      );
      addTearDown(api.close);
      final auth = AuthServiceMock();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(auth: auth),
          routes: {
            '/recuperar-password': (context) => RecuperarPasswordPage(
              service: RecuperacionServiceApi(api),
              emailInicial:
                  ModalRoute.of(context)!.settings.arguments as String,
            ),
          },
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'Ana@example.com',
      );
      await tap(tester, '¿Olvidaste tu contraseña?');
      expect(
        find.widgetWithText(TextFormField, 'Ana@example.com'),
        findsOneWidget,
      );
      await tap(tester, 'Enviar código');
      expect(
        find.textContaining('Si existe una cuenta activa'),
        findsOneWidget,
      );
      expect(find.textContaining('Reenviar en '), findsOneWidget);
      await tap(tester, 'Verificar código');
      expect(pedidos.length, 1);
      await tester.enterText(
        find.byKey(const ValueKey('recuperacion-codigo')),
        '012345',
      );
      await tap(tester, 'Verificar código');
      await tester.enterText(
        find.byKey(const ValueKey('recuperacion-password')),
        'Nueva-123',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recuperacion-confirmacion')),
        'Diferente',
      );
      await tap(tester, 'Guardar contraseña');
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(pedidos.length, 2);
      await tester.enterText(
        find.byKey(const ValueKey('recuperacion-confirmacion')),
        'Nueva-123',
      );
      await tap(tester, 'Guardar contraseña');
      expect(
        find.text('Tu contraseña se actualizó correctamente.'),
        findsOneWidget,
      );
      expect(auth.autenticado, false);
      await tap(tester, 'Volver a ingresar');
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(pedidos.length, 3);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Código inválido conserva el paso y bloquea el reenvío inmediato',
    (tester) async {
      var solicitudes = 0;
      final api = HttpApiClient(
        baseUrl: 'https://api.example.invalid',
        client: MockClient((r) async {
          if (r.url.path.endsWith('forgot-password')) {
            solicitudes++;
            return http.Response('{"reintentarEnSegundos":60}', 202);
          }
          return http.Response(
            '{"title":"Código inválido o vencido"}',
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: RecuperarPasswordPage(
            service: RecuperacionServiceApi(api),
            emailInicial: 'ana@example.com',
          ),
        ),
      );
      await tap(tester, 'Enviar código');
      await tester.enterText(
        find.byKey(const ValueKey('recuperacion-codigo')),
        '123456',
      );
      await tap(tester, 'Verificar código');
      expect(find.text('Código inválido o vencido'), findsOneWidget);
      expect(solicitudes, 1);
      // El reloj de reenvío se basa en la hora real: sin esperar un minuto verificamos que el botón esté bloqueado.
      final reenviar = tester.widget<TextButton>(
        find.ancestor(
          of: find.textContaining('Reenviar en '),
          matching: find.byType(TextButton),
        ),
      );
      expect(reenviar.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('API deshabilitada muestra un error y conserva el email', (
    tester,
  ) async {
    final api = HttpApiClient(
      baseUrl: 'https://api.example.invalid',
      client: MockClient((_) async => http.Response('{}', 503)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: RecuperarPasswordPage(
          service: RecuperacionServiceApi(api),
          emailInicial: 'ana@example.com',
        ),
      ),
    );
    await tap(tester, 'Enviar código');
    expect(
      find.text(
        'La recuperación no está disponible en este momento. Intentá más tarde.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recuperacion-email')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
