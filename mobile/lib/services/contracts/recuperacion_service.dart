import '../../models/permiso_recuperacion.dart';

abstract class RecuperacionService {
  Future<int> solicitarCodigo(String email);
  Future<PermisoRecuperacion> verificarCodigo(String email, String codigo);
  Future<void> restablecer(String token, String password, String confirmacion);
}
