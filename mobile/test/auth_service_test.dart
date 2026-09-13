import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/api_client.dart';
import 'package:huella_cerca/core/network/api_exception.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/services/auth_service.dart';

import 'support/auth_fakes.dart';

http.Response json(Object? data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'Login guarda sesión sin contraseña y me manda solo el access token',
    () async {
      final storage = MemorySessionStorage();
      final api = ApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          if (r.url.path.endsWith('login')) {
            expect(r.method, 'POST');
            expect(jsonDecode(r.body), {
              'email': 'prueba@example.com',
              'password': 'clave-local',
            });
            expect(r.headers['Authorization'], isNull);
            return json(sesionJson());
          }
          expect(r.headers['Authorization'], 'Bearer access-1');
          return json(usuarioJson());
        }),
      );
      final auth = AuthService(api, storage);
      addTearDown(() {
        auth.dispose();
        api.close();
      });
      await auth.restaurar();
      await auth.login(const LoginRequest('prueba@example.com', 'clave-local'));
      expect(auth.autenticado, isTrue);
      expect(storage.value, isNot(contains('clave-local')));
      expect((await auth.miPerfil()).mascotero.nombre, 'Ana');
    },
  );

  test('Registro manda DTO completo y deja sesión iniciada', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        expect(r.url.path, '/api/auth/register');
        final body = jsonDecode(r.body);
        expect(body['localidadId'], 'localidad-1');
        expect(body['passwordConfirm'], '12345678');
        return json(sesionJson(), 201);
      }),
    );
    final auth = AuthService(api, MemorySessionStorage());
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    await auth.registrar(
      const RegisterRequest(
        nombre: 'Ana',
        apellido: 'Prueba',
        email: 'prueba@example.com',
        password: '12345678',
        passwordConfirm: '12345678',
        localidadId: 'localidad-1',
      ),
    );
    expect(auth.autenticado, isTrue);
  });

  test(
    'Restauración renueva JWT vencido y persiste ambos tokens nuevos',
    () async {
      final storage = MemorySessionStorage()
        ..value = sesionTexto(expired: true);
      var refreshes = 0;
      final api = ApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          if (r.url.path.endsWith('refresh')) {
            refreshes++;
            expect(jsonDecode(r.body)['refreshToken'], 'refresh-access-1');
            expect(r.headers['Authorization'], isNull);
            return json(sesionJson(token: 'access-2'));
          }
          expect(r.headers['Authorization'], 'Bearer access-2');
          return json(usuarioJson());
        }),
      );
      final auth = AuthService(api, storage);
      addTearDown(() {
        auth.dispose();
        api.close();
      });
      await auth.restaurar();
      expect(refreshes, 1);
      expect(auth.autenticado, isTrue);
      expect(storage.value, contains('refresh-access-2'));
    },
  );

  test('Dos 401 simultáneos comparten refresh y reintentan una vez', () async {
    var rejecting = false, refreshes = 0;
    final refresh = Completer<http.Response>();
    final api = ApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        if (r.url.path.endsWith('refresh')) {
          refreshes++;
          return refresh.future;
        }
        if (rejecting && r.headers['Authorization'] == 'Bearer access-1') {
          return json({}, 401);
        }
        return json(usuarioJson());
      }),
    );
    final auth = AuthService(
      api,
      MemorySessionStorage()..value = sesionTexto(),
    );
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    rejecting = true;
    final first = auth.getProtegido('api/auth/me');
    final second = auth.getProtegido('api/auth/me');
    await Future<void>.delayed(Duration.zero);
    refresh.complete(json(sesionJson(token: 'access-2')));
    await Future.wait([first, second]);
    expect(refreshes, 1);
  });

  test('Refresh rechazado limpia sesión y no entra en bucle', () async {
    var refreshes = 0;
    final storage = MemorySessionStorage()..value = sesionTexto(expired: true);
    final api = ApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        refreshes++;
        return json({'title': 'La sesión no se puede renovar.'}, 401);
      }),
    );
    final auth = AuthService(api, storage);
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    expect(refreshes, 1);
    expect(auth.autenticado, isFalse);
    expect(storage.value, isNull);
    expect(auth.aviso, isNotNull);
  });

  test(
    'Refresh vencido no se envía y un fallo de red en me conserva sesión',
    () async {
      var calls = 0;
      final storage = MemorySessionStorage()
        ..value = sesionTexto(refreshExpired: true);
      final api = ApiClient(
        baseUrl: 'http://localhost/',
        client: MockClient((r) async {
          calls++;
          throw http.ClientException('sin red');
        }),
      );
      final auth = AuthService(api, storage);
      addTearDown(() {
        auth.dispose();
        api.close();
      });
      await auth.restaurar();
      expect(calls, 0);
      expect(storage.value, isNull);
      storage.value = sesionTexto();
      await auth.restaurar();
      expect(auth.autenticado, isTrue);
      expect(storage.value, isNotNull);
      expect(auth.aviso, isNotNull);
    },
  );

  test('Logout borra sesión local aunque el servidor no responda', () async {
    final storage = MemorySessionStorage()..value = sesionTexto();
    final api = ApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        if (r.url.path.endsWith('logout')) {
          expect(jsonDecode(r.body)['refreshToken'], 'refresh-access-1');
          throw http.ClientException('sin red');
        }
        return json(usuarioJson());
      }),
    );
    final auth = AuthService(api, storage);
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    await auth.logout();
    expect(auth.autenticado, isFalse);
    expect(storage.value, isNull);
    expect(auth.aviso, contains('No pudimos confirmar'));
  });

  test('401 de credenciales no intenta refresh', () async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost/',
      client: MockClient((r) async {
        calls++;
        expect(r.url.path, '/api/auth/login');
        return json({'title': 'Email o contraseña inválidos.'}, 401);
      }),
    );
    final auth = AuthService(api, MemorySessionStorage());
    addTearDown(() {
      auth.dispose();
      api.close();
    });
    await auth.restaurar();
    await expectLater(
      auth.login(const LoginRequest('a@b.com', 'error')),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          'Email o contraseña inválidos.',
        ),
      ),
    );
    expect(calls, 1);
    expect(auth.autenticado, isFalse);
  });
}
