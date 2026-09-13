import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/api_client.dart';
import 'package:huella_cerca/core/network/api_exception.dart';
import 'package:huella_cerca/services/ubicacion_service.dart';

void main() {
  test('HTTP 503 produce error de servicio sin exponer el cuerpo', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((_) async => http.Response('detalle interno', 503)),
    );
    addTearDown(api.close);
    await expectLater(
      api.getText('health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 503)
            .having(
              (e) => e.message,
              'mensaje',
              isNot(contains('detalle interno')),
            ),
      ),
    );
  });
  test('Timeout produce un error recuperable', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.close);
    await expectLater(
      api.getText('health'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          contains('tardó'),
        ),
      ),
    );
  });
  for (final body in ['no es JSON', '{}', '[{"id": 3}]']) {
    test('Rechaza JSON o contrato incorrecto: $body', () async {
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(
        UbicacionService(api).getProvincias(),
        throwsA(isA<ApiException>()),
      );
    });
  }
}
