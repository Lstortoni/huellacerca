import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/preferencias_locales.dart';
import '../../core/network/api_exception.dart';
import '../../models/provincia_dto.dart';
import '../../models/localidad_dto.dart';
import '../contracts/ubicacion_service.dart';

class UbicacionServiceApi implements UbicacionService {
  UbicacionServiceApi(this._api, [PreferenciasLocales? preferencias])
    : _preferencias = preferencias ?? PreferenciasEnMemoria();
  final ApiClient _api;
  final PreferenciasLocales _preferencias;
  static const _claveRecientes = 'huella_cerca_ubicaciones_recientes';
  static const _maxRecientes = 5;

  @override
  Future<List<LocalidadDto>> recientes() async {
    try {
      final texto = await _preferencias.leer(_claveRecientes);
      if (texto == null) return [];
      return (jsonDecode(texto) as List)
          .map((j) => LocalidadDto.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // Dato local dañado o sin almacenamiento: no bloquea elegir.
    }
  }

  @override
  Future<void> recordar(LocalidadDto localidad) async {
    final lista = [
      localidad,
      ...(await recientes()).where((l) => l.id != localidad.id),
    ].take(_maxRecientes).map((l) => l.toJson()).toList();
    try {
      await _preferencias.guardar(_claveRecientes, jsonEncode(lista));
    } catch (_) {
      // Las recientes son una comodidad: un fallo no impide continuar.
    }
  }

  @override
  Future<LocalidadDto> getLocalidad(String id) async {
    final data = await _api.getJson('api/localidades/$id');
    try {
      return LocalidadDto.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException('No pudimos leer la localidad.');
    }
  }

  @override
  Future<LocalidadesPagina> getLocalidades({
    String? provinciaId,
    String busqueda = '',
    int pagina = 1,
  }) async {
    final data = await _api.getJson(
      'api/localidades',
      query: {
        'provinciaId': ?provinciaId,
        'busqueda': busqueda,
        'pagina': '$pagina',
        'tamanoPagina': '20',
      },
    );
    try {
      final json = data as Map<String, dynamic>;
      return LocalidadesPagina(
        (json['items'] as List)
            .map((j) => LocalidadDto.fromJson(j as Map<String, dynamic>))
            .toList(),
        json['total'] as int,
      );
    } catch (_) {
      throw const ApiException(
        'No pudimos leer las localidades. Volvé a intentar.',
      );
    }
  }

  @override
  Future<List<ProvinciaDto>> getProvincias() async {
    final data = await _api.getJson(
      'api/provincias',
      query: {'paisCodigo': 'AR'},
    );
    try {
      if (data is! List) throw const FormatException('Se esperaba una lista.');
      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Provincia inválida.');
        }
        return ProvinciaDto.fromJson(item);
      }).toList();
    } on FormatException {
      throw const ApiException(
        'No pudimos leer las provincias. Volvé a intentar.',
      );
    }
  }
}
