import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/aviso_push.dart';
import '../contracts/mensajeria_push.dart';

class MensajeriaPushFirebase implements MensajeriaPush {
  final FirebaseMessaging _firebase = FirebaseMessaging.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<String>? _id;

  @override
  Future<String> instalacionId() => _id ??= _leerId();

  Future<String> _leerId() async {
    const key = 'huella_cerca_instalacion_push';
    final guardado = await _storage.read(key: key);
    if (guardado != null) return guardado;
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _storage.write(key: key, value: id);
    return id;
  }

  @override
  Future<bool> permiso({required bool solicitar}) async {
    // Android 13 no distingue "nunca solicitado" de "denegado"; recordamos el pedido.
    const key = 'huella_cerca_permiso_push_solicitado';
    var settings = await _firebase.getNotificationSettings();
    if (solicitar && await _storage.read(key: key) == null) {
      await _storage.write(key: key, value: 'true');
      settings = await _firebase.requestPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() =>
      _firebase.getToken().timeout(const Duration(seconds: 20));
  @override
  Future<void> borrarToken() =>
      _firebase.deleteToken().timeout(const Duration(seconds: 20));
  @override
  Future<AvisoPush?> mensajeInicial() async {
    final message = await _firebase.getInitialMessage();
    return message == null ? null : AvisoPush.desdeDatos(message.data);
  }

  Stream<AvisoPush> _avisos(Stream<RemoteMessage> source) => source
      .map((m) => AvisoPush.desdeDatos(m.data))
      .where((m) => m != null)
      .cast<AvisoPush>();
  @override
  Stream<String> get cambiosToken => _firebase.onTokenRefresh;
  @override
  Stream<AvisoPush> get recibidos => _avisos(FirebaseMessaging.onMessage);
  @override
  Stream<AvisoPush> get abiertos =>
      _avisos(FirebaseMessaging.onMessageOpenedApp);
}
