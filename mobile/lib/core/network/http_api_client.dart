import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_client.dart';

/// Un único punto para configurar URL, tiempo de espera y errores HTTP.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = ApiConfig.timeout,
  }) : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  @override
  String resolverUrl(String path) => _baseUri.resolve(path).toString();
  @override
  Future<Object?> subirFoto(
    String path,
    Uint8List bytes, {
    required String accessToken,
  }) async {
    try {
      final request = http.MultipartRequest('PUT', _baseUri.resolve(path))
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(
          http.MultipartFile.fromBytes('archivo', bytes, filename: 'foto'),
        );
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode >= 500
              ? 'No pudimos guardar la foto. Tu aviso sigue creado; podés reintentar.'
              : _errorMessage(response),
          statusCode: response.statusCode,
        );
      }
      return _decode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ApiException(
        'La subida tardó demasiado. Revisá el aviso y volvé a intentar.',
      );
    } on http.ClientException {
      throw const ApiException('No pudimos subir la foto. Revisá tu conexión.');
    }
  }

  @override
  Future<String> getText(
    String path, {
    Map<String, String>? query,
    String? accessToken,
    Map<String, Object?>? body,
  }) => _request(
    body == null ? 'GET' : 'POST',
    path,
    query: query,
    accessToken: accessToken,
    body: body,
  );

  Future<String> _request(
    String method,
    String path, {
    Map<String, String>? query,
    String? accessToken,
    Map<String, Object?>? body,
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        if (body != null) 'Content-Type': 'application/json',
      };
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode >= 500
              ? 'El servicio no está disponible. Intentá nuevamente en unos minutos.'
              : _errorMessage(response),
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

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) async {
    final text = await getText(path, query: query, accessToken: accessToken);
    return _decode(text);
  }

  @override
  Future<Object?> postJson(String path, Map<String, Object?> body) async {
    final text = await getText(path, body: body);
    return text.isEmpty ? null : _decode(text);
  }

  Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      throw const ApiException(
        'Recibimos una respuesta que no pudimos interpretar.',
      );
    }
  }

  @override
  Future<Object?> enviarJson(
    String method,
    String path, {
    required String accessToken,
    Map<String, Object?>? body,
  }) async {
    final text = await _request(
      method,
      path,
      accessToken: accessToken,
      body: body,
    );
    return text.isEmpty ? null : _decode(text);
  }

  @override
  void close() => _client.close();

  String _errorMessage(http.Response response) {
    if (response.statusCode == 429) {
      return 'Hiciste varios intentos. Esperá un minuto y volvé a intentar.';
    }
    try {
      final problem = jsonDecode(utf8.decode(response.bodyBytes));
      if (problem is Map<String, dynamic>) {
        final errors = problem['errors'];
        if (errors is Map) {
          return errors.values.expand((v) => v is List ? v : [v]).join('\n');
        }
        if (problem['title'] is String) return problem['title'] as String;
      }
    } on FormatException {
      /* Usar mensaje genérico. */
    }
    return 'No pudimos completar la consulta. Intentá nuevamente.';
  }
}
