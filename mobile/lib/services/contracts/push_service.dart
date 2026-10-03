import '../../models/aviso_push.dart';

abstract class PushService {
  Stream<AvisoPush> get recibidos;
  Stream<AvisoPush> get abiertos;
  Future<void> iniciar();
  Future<void> sincronizar();
  Future<void> desvincular();
  void dispose();
}
