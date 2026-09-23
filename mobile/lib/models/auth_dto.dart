/// Contratos JSON de autenticación. Las contraseñas no se guardan en la sesión.
class MascoteroDto {
  const MascoteroDto({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.telefono,
    required this.localidadId,
  });
  final String id, nombre, apellido, localidadId;
  final String? telefono;

  /// Iniciales para el avatar, por ejemplo "LS".
  String get iniciales => [nombre, apellido]
      .where((s) => s.trim().isNotEmpty)
      .map((s) => s.trim()[0].toUpperCase())
      .join();
  factory MascoteroDto.fromJson(Map<String, dynamic> j) => MascoteroDto(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    apellido: j['apellido'] as String,
    telefono: j['telefono'] as String?,
    localidadId: j['localidadId'] as String,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'localidadId': localidadId,
  };
}

class UsuarioDto {
  const UsuarioDto({
    required this.id,
    required this.email,
    required this.emailConfirmado,
    required this.mascotero,
  });
  final String id, email;
  final bool emailConfirmado;
  final MascoteroDto mascotero;
  factory UsuarioDto.fromJson(Map<String, dynamic> j) => UsuarioDto(
    id: j['id'] as String,
    email: j['email'] as String,
    emailConfirmado: j['emailConfirmado'] as bool,
    mascotero: MascoteroDto.fromJson(j['mascotero'] as Map<String, dynamic>),
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'emailConfirmado': emailConfirmado,
    'mascotero': mascotero.toJson(),
  };
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
    required this.refreshExpiresAtUtc,
    required this.usuario,
  });
  final String accessToken, refreshToken;
  final DateTime expiresAtUtc, refreshExpiresAtUtc;
  final UsuarioDto usuario;
  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
    accessToken: j['accessToken'] as String,
    refreshToken: j['refreshToken'] as String,
    expiresAtUtc: DateTime.parse(j['expiresAtUtc'] as String),
    refreshExpiresAtUtc: DateTime.parse(j['refreshExpiresAtUtc'] as String),
    usuario: UsuarioDto.fromJson(j['usuario'] as Map<String, dynamic>),
  );
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAtUtc': expiresAtUtc.toIso8601String(),
    'refreshExpiresAtUtc': refreshExpiresAtUtc.toIso8601String(),
    'usuario': usuario.toJson(),
  };
}

class LoginRequest {
  const LoginRequest(this.email, this.password);
  final String email, password;
  Map<String, Object?> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    this.telefono,
    required this.localidadId,
  });
  final String nombre, apellido, email, password, passwordConfirm, localidadId;
  final String? telefono;
  Map<String, Object?> toJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'password': password,
    'passwordConfirm': passwordConfirm,
    'telefono': telefono,
    'localidadId': localidadId,
  };
}
