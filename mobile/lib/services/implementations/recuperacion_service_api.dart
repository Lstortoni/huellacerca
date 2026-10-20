import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/permiso_recuperacion.dart';
import '../contracts/recuperacion_service.dart';

class RecuperacionServiceApi implements RecuperacionService {
  const RecuperacionServiceApi(this._api);
  final ApiClient _api;

  @override
  Future<int> solicitarCodigo(String email) async {
    final data = await _api.postJson('api/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
    final espera = data is Map ? data['reintentarEnSegundos'] : null;
    return espera is int && espera >= 60 && espera <= 3600 ? espera : 60;
  }

  @override
  Future<PermisoRecuperacion> verificarCodigo(
    String email,
    String codigo,
  ) async {
    final data = await _api.postJson('api/auth/verify-reset-code', {
      'email': email.trim().toLowerCase(),
      'codigo': codigo,
    });
    try {
      final json = data as Map<String, dynamic>;
      final token = json['resetToken'] as String;
      if (token.isEmpty) throw const FormatException();
      return PermisoRecuperacion(
        token,
        DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
      );
    } catch (_) {
      throw const ApiException(
        'No pudimos interpretar la autorización. Solicitá un nuevo código.',
      );
    }
  }

  @override
  Future<void> restablecer(
    String token,
    String password,
    String confirmacion,
  ) async {
    await _api.postJson('api/auth/reset-password', {
      'resetToken': token,
      'password': password,
      'passwordConfirm': confirmacion,
    });
  }
}
