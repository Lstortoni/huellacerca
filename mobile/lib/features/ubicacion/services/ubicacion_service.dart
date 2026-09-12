import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/provincia_dto.dart';

class UbicacionService {
  const UbicacionService(this._api);
  final ApiClient _api;

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
