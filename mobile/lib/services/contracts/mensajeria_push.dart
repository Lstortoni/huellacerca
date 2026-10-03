import '../../models/aviso_push.dart';

/// Acceso al dispositivo; no conoce nuestra API ni la sesión.
abstract class MensajeriaPush {
  Future<String> instalacionId();
  Future<bool> permiso({required bool solicitar});
  Future<String?> token();
  Future<void> borrarToken();
  Future<AvisoPush?> mensajeInicial();
  Stream<String> get cambiosToken;
  Stream<AvisoPush> get recibidos;
  Stream<AvisoPush> get abiertos;
}
