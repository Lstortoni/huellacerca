import 'package:flutter/foundation.dart';

import '../../models/auth_dto.dart';

/// Contrato de sesión observable. No define HTTP ni almacenamiento.
/// Listenable permite a la barra escuchar cambios sin conocer la implementación.
abstract class AuthService implements Listenable {
  UsuarioDto? get usuario;
  bool get autenticado;
  bool get restaurando;
  bool get ocupado;
  String? get aviso;
  Future<void> restaurar();
  Future<void> login(LoginRequest request);
  Future<void> registrar(RegisterRequest request);
  Future<UsuarioDto> miPerfil();
  Future<void> logout();

  /// GET autenticado; la implementación coordina la renovación cuando corresponde.
  Future<Object?> getProtegido(String path);

  /// Lo llama el dueño de la sesión al liberar las dependencias de la app.
  void dispose();
}
