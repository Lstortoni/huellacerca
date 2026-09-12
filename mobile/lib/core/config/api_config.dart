/// Configuración compartida. Se puede cambiar sin editar código con --dart-define.
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  static const timeout = Duration(seconds: 15);
}
