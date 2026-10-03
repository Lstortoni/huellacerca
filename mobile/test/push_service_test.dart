import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/aviso_push.dart';
import 'package:huella_cerca/services/contracts/mensajeria_push.dart';
import 'package:huella_cerca/services/implementations/push_service_api.dart';

import 'support/service_mocks.dart';

class PushAuth extends AuthServiceMock {
  final operaciones = <String>[];
  final tokens = <Object?>[];
  Completer<void>? espera;
  @override
  Future<Object?> putProtegido(String path, Map<String, Object?> body) async {
    operaciones.add('PUT');
    tokens.add(body['token']);
    await espera?.future;
    operaciones.add('PUT terminado');
    return null;
  }

  @override
  Future<void> deleteProtegido(String path) async {
    operaciones.add('DELETE');
  }
}

class MensajeriaFake implements MensajeriaPush {
  bool permitido = true;
  int borrados = 0;
  String actual = 'token-1';
  final cambios = StreamController<String>.broadcast();
  final mensajes = StreamController<AvisoPush>.broadcast();
  final toques = StreamController<AvisoPush>.broadcast();
  @override
  Future<String> instalacionId() async => 'instalacion';
  @override
  Future<bool> permiso({required bool solicitar}) async => permitido;
  @override
  Future<String?> token() async => actual;
  @override
  Future<void> borrarToken() async {
    borrados++;
  }

  @override
  Future<AvisoPush?> mensajeInicial() async => null;
  @override
  Stream<String> get cambiosToken => cambios.stream;
  @override
  Stream<AvisoPush> get recibidos => mensajes.stream;
  @override
  Stream<AvisoPush> get abiertos => toques.stream;
  Future<void> close() async {
    await cambios.close();
    await mensajes.close();
    await toques.close();
  }
}

void main() {
  late PushAuth auth;
  late MensajeriaFake mensajes;
  late PushServiceApi push;
  const login = LoginRequest('test@example.com', 'password');

  setUp(() {
    auth = PushAuth();
    mensajes = MensajeriaFake();
    push = PushServiceApi(auth, mensajes);
  });
  tearDown(() async {
    push.dispose();
    await mensajes.close();
    auth.dispose();
  });

  test(
    'registra después del login, evita duplicar y actualiza token rotado',
    () async {
      await push.iniciar();
      expect(auth.operaciones, isEmpty);
      await auth.login(login);
      await push.sincronizar();
      expect(auth.tokens, ['token-1']);
      await push.sincronizar();
      expect(auth.tokens.length, 1);
      mensajes.actual = 'token-2';
      mensajes.cambios.add('token-2');
      await Future<void>.delayed(Duration.zero);
      await push.sincronizar();
      expect(auth.tokens, ['token-1', 'token-2']);
    },
  );

  test('permiso denegado desvincula y no registra token', () async {
    mensajes.permitido = false;
    await auth.login(login);
    await push.iniciar();
    await push.sincronizar();
    expect(auth.tokens, isEmpty);
    expect(auth.operaciones, contains('DELETE'));
  });

  test('logout espera el registro en vuelo antes de desvincular', () async {
    await auth.login(login);
    auth.espera = Completer<void>();
    await push.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(auth.operaciones, ['PUT']);
    final cierre = push.desvincular();
    auth.espera!.complete();
    await cierre;
    expect(auth.operaciones, ['PUT', 'PUT terminado', 'DELETE']);
    expect(mensajes.borrados, 1);
    await auth.logout();
    await auth.login(login);
    await push.sincronizar();
    expect(auth.tokens.length, 2);
  });

  test('primer plano filtra notificaciones de otra cuenta', () async {
    await auth.login(login);
    await push.iniciar();
    await push.sincronizar();
    final recibidos = <AvisoPush>[];
    final sub = push.recibidos.listen(recibidos.add);
    mensajes.mensajes.add(
      const AvisoPush(notificacionId: '1', mascoteroId: 'otra-cuenta'),
    );
    mensajes.mensajes.add(
      const AvisoPush(notificacionId: '2', mascoteroId: 'mascotero-1'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(recibidos.map((x) => x.notificacionId), ['2']);
    await sub.cancel();
  });

  test('descarta payload de prueba o malformado', () {
    expect(AvisoPush.desdeDatos({}), isNull);
    expect(
      AvisoPush.desdeDatos({
        'tipo': 'coincidencia',
        'notificacionId': '../otra-ruta',
        'mascoteroId': 'a',
      }),
      isNull,
    );
  });
}
