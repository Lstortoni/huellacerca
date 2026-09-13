import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/provincia_dto.dart';
import '../models/localidad_dto.dart';

class UbicacionService {
  const UbicacionService(this._api);
  final ApiClient _api;

  Future<LocalidadesPagina> getLocalidades(
    String provinciaId, {
    String busqueda = '',
    int pagina = 1,
  }) async {
    final data = await _api.getJson(
      'api/localidades',
      query: {
        'provinciaId': provinciaId,
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
