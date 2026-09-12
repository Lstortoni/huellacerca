/// Error que la pantalla puede mostrar sin exponer detalles internos.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}
