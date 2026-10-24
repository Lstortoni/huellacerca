import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huella_cerca/core/network/http_api_client.dart';
import 'package:huella_cerca/core/storage/preferencias_locales.dart';
import 'package:huella_cerca/models/localidad_dto.dart';
import 'package:huella_cerca/services/implementations/ubicacion_service_api.dart';
import 'package:huella_cerca/widgets/campo_ubicacion.dart';
import 'package:huella_cerca/widgets/selector_ubicacion.dart';

import 'comunidad_pages_test.dart' show elegirLocalidad;
import 'support/service_mocks.dart';

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// API simulada: 45 localidades en páginas de 20, una localidad de perfil y
/// dos provincias.
(HttpApiClient, List<Map<String, String>>) _api() {
  final consultas = <Map<String, String>>[];
  final api = HttpApiClient(
    baseUrl: 'http://localhost/',
    client: MockClient((r) async {
      if (r.url.path == '/api/provincias') {
        return _json([
          {'id': 'p-ba', 'nombre': 'Buenos Aires', 'paisCodigo': 'AR'},
          {'id': 'p-co', 'nombre': 'Córdoba', 'paisCodigo': 'AR'},
        ]);
      }
      if (r.url.path == '/api/localidades/l-perfil') {
        return _json({
          'id': 'l-perfil',
          'nombre': 'Lanús',
          'provinciaId': 'p-ba',
          'provincia': 'Buenos Aires',
        });
      }
      consultas.add(r.url.queryParameters);
      final pagina = int.parse(r.url.queryParameters['pagina']!);
      final cantidad = pagina < 3 ? 20 : 5;
      return _json({
        'items': [
          for (var i = 0; i < cantidad; i++)
            {
              'id': 'l$pagina-$i',
              'nombre': 'La Plata $pagina-$i',
              'provinciaId': 'p-ba',
              'provincia': 'Buenos Aires',
            },
        ],
        'total': 45,
      });
    }),
  );
  return (api, consultas);
}

void main() {
  test(
    'Busca en todo el país, lee una localidad y recuerda recientes',
    () async {
      final (api, consultas) = _api();
      addTearDown(api.close);
      final service = UbicacionServiceApi(api, PreferenciasEnMemoria());
      final pagina = await service.getLocalidades(busqueda: 'la pl');
      expect(consultas.single.containsKey('provinciaId'), isFalse);
      expect(consultas.single['busqueda'], 'la pl');
      expect(pagina.items.first.etiqueta, 'La Plata 1-0, Buenos Aires');
      expect(
        (await service.getLocalidad('l-perfil')).etiqueta,
        'Lanús, Buenos Aires',
      );
      for (var i = 0; i < 7; i++) {
        await service.recordar(LocalidadDto('l$i', 'Localidad $i', 'p'));
      }
      await service.recordar(const LocalidadDto('l3', 'Localidad 3', 'p'));
      final recientes = await service.recientes();
      expect(recientes.length, 5); // Máximo 5, sin repetir.
      expect(recientes.map((l) => l.id), ['l3', 'l6', 'l5', 'l4', 'l2']);
    },
  );

  testWidgets(
    'Sin texto sugiere tu localidad y recientes; con 2 letras busca',
    (tester) async {
      final (api, consultas) = _api();
      addTearDown(api.close);
      final service = UbicacionServiceApi(api, PreferenciasEnMemoria());
      await service.recordar(
        const LocalidadDto('l-r', 'Quilmes', 'p-ba', 'Buenos Aires'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectorUbicacion(
              ubicacion: service,
              localidadPerfilId: 'l-perfil',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu localidad'), findsOneWidget);
      expect(find.text('Lanús'), findsOneWidget);
      expect(find.text('Recientes'), findsOneWidget);
      expect(find.text('Quilmes'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'l');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(consultas, isEmpty); // Con una letra no consulta.
      await tester.enterText(find.byType(TextField), 'la');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(consultas.single['busqueda'], 'la');
      expect(find.text('La Plata 1-0'), findsOneWidget);
      expect(
        find.text('Buenos Aires'),
        findsWidgets,
      ); // Provincia como subtítulo.
      // Al desplazarse carga la página siguiente, sin botones de página.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(consultas.last['pagina'], '2');
    },
  );

  testWidgets('En filtros ofrece provincias enteras', (tester) async {
    final (api, _) = _api();
    addTearDown(api.close);
    UbicacionElegida? elegida;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => elegida = await SelectorUbicacion.mostrar(
                context,
                ubicacion: UbicacionServiceApi(api, PreferenciasEnMemoria()),
                permitirProvincia: true,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'cord');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Toda la provincia'), findsOneWidget);
    await tester.tap(find.text('Córdoba'));
    await tester.pumpAndSettle();
    expect(elegida!.localidad, isNull);
    expect(elegida!.idProvincia, 'p-co');
    expect(elegida!.etiqueta, 'Córdoba (toda la provincia)');
  });

  testWidgets(
    'El campo precarga el perfil, recuerda la elegida y se puede quitar',
    (tester) async {
      final ubicacion = UbicacionServiceMock();
      final cambios = <(String?, String?)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampoUbicacion(
              service: ubicacion,
              localidadPerfilId: 'localidad-1',
              precargarPerfil: true,
              onChanged: (p, l) => cambios.add((p, l)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Localidad simulada, Provincia simulada'),
        findsOneWidget,
      );
      expect(cambios.last, ('provincia-demo', 'localidad-demo'));
      await elegirLocalidad(tester);
      expect(ubicacion.guardadas.single.id, 'localidad-demo');
      await tester.tap(find.byTooltip('Quitar ubicación'));
      await tester.pumpAndSettle();
      expect(cambios.last, (null, null));
      expect(find.text('Todas las localidades'), findsOneWidget);
    },
  );
}
