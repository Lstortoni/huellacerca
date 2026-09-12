import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Un único punto para configurar URL, tiempo de espera y errores HTTP.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = ApiConfig.timeout,
  }) : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;

  Future<String> getText(String path, {Map<String, String>? query}) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode >= 500
              ? 'El servicio no está disponible. Intentá nuevamente en unos minutos.'
              : 'No pudimos completar la consulta. Intentá nuevamente.',
          statusCode: response.statusCode,
        );
      }
      return utf8.decode(response.bodyBytes);
    } on TimeoutException {
      throw const ApiException(
        'La conexión tardó demasiado. Volvé a intentar.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No pudimos conectarnos. Revisá tu conexión e intentá nuevamente.',
      );
    } on FormatException {
      throw const ApiException(
        'Recibimos una respuesta que no pudimos interpretar.',
      );
    }
  }

  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    final text = await getText(path, query: query);
    try {
      return jsonDecode(text);
    } on FormatException {
      throw const ApiException(
        'Recibimos una respuesta que no pudimos interpretar.',
      );
    }
  }

  void close() => _client.close();
}
