import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../models/auth_dto.dart';
import '../contracts/auth_service.dart';

/// Estado de sesión compartido. Las páginas y la barra escuchan sus cambios.
class AuthServiceApi extends ChangeNotifier implements AuthService {
  AuthServiceApi(this._api, this._storage);
  final ApiClient _api;
  final SessionStorage _storage;
  AuthResponse? _session;
  Future<void>? _refreshing;
  @override
  bool restaurando = true;
  @override
  bool ocupado = false;
  @override
  String? aviso;
  bool _disposed = false;
  int _version = 0;
  @override
  UsuarioDto? get usuario => _session?.usuario;
  @override
  bool get autenticado => _session != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> restaurar() async {
    restaurando = true;
    aviso = null;
    _notify();
    try {
      final value = await _storage.read();
      if (value != null) {
        try {
          _session = AuthResponse.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          );
        } catch (_) {
          await _clear();
          throw const ApiException(
            'No pudimos recuperar la sesión. Ingresá nuevamente.',
          );
        }
        if (!_session!.refreshExpiresAtUtc.isAfter(DateTime.now().toUtc())) {
          await _clear();
        } else {
          await miPerfil();
        }
      }
    } on ApiException catch (e) {
      aviso = e.message;
    } catch (_) {
      aviso = 'No pudimos leer la sesión guardada. Volvé a intentar.';
    } finally {
      restaurando = false;
      _notify();
    }
  }

  @override
  Future<void> login(LoginRequest request) =>
      _autenticar('api/auth/login', request.toJson());
  @override
  Future<void> registrar(RegisterRequest request) =>
      _autenticar('api/auth/register', request.toJson());

  Future<void> _autenticar(String path, Map<String, Object?> body) async {
    if (ocupado || restaurando) {
      throw const ApiException('Esperá a que termine la operación actual.');
    }
    ocupado = true;
    aviso = null;
    _notify();
    try {
      final response = _parse(await _api.postJson(path, body));
      await _save(response);
      _version++;
    } finally {
      ocupado = false;
      _notify();
    }
  }

  AuthResponse _parse(Object? value) {
    try {
      return AuthResponse.fromJson(value as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException(
        'No pudimos interpretar la respuesta de sesión.',
      );
    }
  }

  Future<void> _save(AuthResponse response) async {
    try {
      await _storage.write(jsonEncode(response.toJson()));
    } catch (_) {
      throw const ApiException(
        'No pudimos guardar la sesión de forma segura. Volvé a ingresar.',
      );
    }
    _session = response;
    _notify();
  }

  Future<void> _clear() async {
    _session = null;
    _version++;
    _notify();
    await _storage.clear();
  }

  /// Comparte una sola renovación entre consultas simultáneas.
  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing!;
    final task = _renovar();
    _refreshing = task;
    try {
      await task;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _renovar() async {
    final current = _session;
    final version = _version;
    if (current == null) {
      throw const ApiException('Ingresá para continuar.', statusCode: 401);
    }
    if (!current.refreshExpiresAtUtc.isAfter(DateTime.now().toUtc())) {
      await _clear();
      throw const ApiException(
        'Tu sesión venció. Volvé a ingresar.',
        statusCode: 401,
      );
    }
    try {
      final response = _parse(
        await _api.postJson('api/auth/refresh', {
          'refreshToken': current.refreshToken,
        }),
      );
      if (version != _version) {
        throw const ApiException('La sesión cambió. Volvé a intentar.');
      }
      await _save(response);
    } catch (_) {
      // Ante una respuesta perdida no repetir un refresh que pudo haber rotado.
      if (version == _version) await _clear();
      rethrow;
    }
  }

  /// Se reintenta únicamente un 401, nunca errores de red ni de servidor.
  @override
  Future<Object?> getProtegido(String path) =>
      _protegido((token) => _api.getJson(path, accessToken: token));

  @override
  Future<Object?> postProtegido(String path, Map<String, Object?> body) =>
      _protegido(
        (token) =>
            _api.enviarJson('POST', path, accessToken: token, body: body),
      );

  @override
  Future<Object?> patchProtegido(String path) =>
      _protegido((token) => _api.enviarJson('PATCH', path, accessToken: token));

  Future<Object?> _protegido(
    Future<Object?> Function(String token) enviar,
  ) async {
    final version = _version;
    if (_session == null) {
      throw const ApiException('Ingresá para continuar.', statusCode: 401);
    }
    if (!_session!.expiresAtUtc.isAfter(DateTime.now().toUtc())) {
      await _refresh();
    }
    if (version != _version || _session == null) {
      throw const ApiException(
        'La sesión cambió. Volvé a intentar.',
        statusCode: 401,
      );
    }
    final token = _session!.accessToken;
    try {
      return await enviar(token);
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      if (version != _version) rethrow;
      if (_session == null) rethrow;
      if (_session!.accessToken == token) await _refresh();
      if (version != _version || _session == null) {
        throw const ApiException(
          'La sesión cambió. Volvé a ingresar.',
          statusCode: 401,
        );
      }
      try {
        return await enviar(_session!.accessToken);
      } on ApiException catch (retry) {
        if (retry.statusCode == 401 && version == _version) await _clear();
        rethrow;
      }
    }
  }

  @override
  Future<UsuarioDto> miPerfil() async {
    final version = _version;
    final data = await getProtegido('api/auth/me');
    try {
      final user = UsuarioDto.fromJson(data as Map<String, dynamic>);
      final current = _session;
      if (current != null && version == _version) {
        _session = AuthResponse(
          accessToken: current.accessToken,
          refreshToken: current.refreshToken,
          expiresAtUtc: current.expiresAtUtc,
          refreshExpiresAtUtc: current.refreshExpiresAtUtc,
          usuario: user,
        );
        _notify();
      }
      return user;
    } on TypeError {
      throw const ApiException('No pudimos interpretar tu perfil.');
    }
  }

  @override
  Future<void> logout() async {
    if (ocupado || restaurando) return;
    ocupado = true;
    _notify();
    try {
      try {
        await _refreshing;
      } catch (_) {
        /* La renovación ya limpió la sesión. */
      }
      final token = _session?.refreshToken;
      await _clear();
      aviso = null;
      if (token != null) {
        try {
          await _api.postJson('api/auth/logout', {'refreshToken': token});
        } on ApiException {
          aviso = 'Saliste de este dispositivo. No pudimos confirmar el cierre en el servidor.';
        }
      }
    } catch (_) {
      aviso = 'No pudimos borrar la sesión guardada. Volvé a intentar cerrar sesión.';
    } finally {
      ocupado = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
