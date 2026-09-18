import 'package:flutter/foundation.dart';
import 'package:huella_cerca/core/network/api_client.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/localidad_dto.dart';
import 'package:huella_cerca/models/provincia_dto.dart';
import 'package:huella_cerca/services/contracts/auth_service.dart';
import 'package:huella_cerca/services/contracts/ubicacion_service.dart';

import 'auth_fakes.dart';

/// Doble completo: no llama a HTTP ni usa almacenamiento nativo.
class AuthServiceMock extends ChangeNotifier implements AuthService {
  UsuarioDto? _usuario;
  int restores = 0, disposals = 0, logins = 0;
  @override
  UsuarioDto? get usuario => _usuario;
  @override
  bool get autenticado => _usuario != null;
  @override
  bool get restaurando => false;
  @override
  bool get ocupado => false;
  @override
  String? get aviso => null;
  @override
  Future<void> restaurar() async {
    restores++;
  }

  @override
  Future<void> login(LoginRequest request) async {
    logins++;
    _usuario = UsuarioDto.fromJson(usuarioJson());
    notifyListeners();
  }

  @override
  Future<void> registrar(RegisterRequest request) async {
    _usuario = UsuarioDto.fromJson(usuarioJson());
    notifyListeners();
  }

  @override
  Future<UsuarioDto> miPerfil() async => _usuario!;
  @override
  Future<void> logout() async {
    _usuario = null;
    notifyListeners();
  }

  @override
  Future<Object?> getProtegido(String path) async => usuarioJson();
  @override
  Future<Object?> postProtegido(String path, Map<String, Object?> body) =>
      throw UnimplementedError();
  @override
  Future<Object?> patchProtegido(String path) => throw UnimplementedError();
  @override
  Future<Object?> putProtegido(String path, Map<String, Object?> body) =>
      throw UnimplementedError();
  @override
  Future<void> deleteProtegido(String path) => throw UnimplementedError();
  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

class UbicacionServiceMock implements UbicacionService {
  int consultas = 0;
  @override
  Future<List<ProvinciaDto>> getProvincias() async {
    consultas++;
    return [
      const ProvinciaDto(
        id: 'provincia-demo',
        nombre: 'Provincia simulada',
        paisCodigo: 'AR',
      ),
    ];
  }

  @override
  Future<LocalidadesPagina> getLocalidades(
    String provinciaId, {
    String busqueda = '',
    int pagina = 1,
  }) async => LocalidadesPagina([
    LocalidadDto('localidad-demo', 'Localidad simulada', provinciaId),
  ], 1);
}

/// El inicio todavía consulta health. Las demás consultas deben pasar por servicios.
class ApiClientMock implements ApiClient {
  @override
  Future<Object?> enviarJson(
    String method,
    String path, {
    required String accessToken,
    Map<String, Object?>? body,
  }) => throw UnimplementedError();
  int closes = 0;
  @override
  Future<String> getText(
    String path, {
    Map<String, String>? query,
    String? accessToken,
    Map<String, Object?>? body,
  }) async {
    if (path != 'health') throw StateError('Consulta inesperada: $path');
    return 'Healthy';
  }

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) => throw StateError(
    'Los datos de esta prueba deben venir del servicio simulado.',
  );
  @override
  Future<Object?> postJson(String path, Map<String, Object?> body) =>
      throw StateError(
        'El login de esta prueba debe venir del servicio simulado.',
      );
  @override
  void close() {
    closes++;
  }
}
