/// Transporte que consumen los servicios. No expone tipos del paquete http.
abstract class ApiClient {
  Future<String> getText(
    String path, {
    Map<String, String>? query,
    String? accessToken,
    Map<String, Object?>? body,
  });
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  });
  Future<Object?> postJson(String path, Map<String, Object?> body);
  Future<Object?> enviarJson(
    String method,
    String path, {
    required String accessToken,
    Map<String, Object?>? body,
  });
  void close();
}
