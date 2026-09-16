import '../../core/network/api_client.dart';
import '../../models/pagina_dto.dart';
import '../../models/recomendacion_dto.dart';
import '../contracts/auth_service.dart';
import '../contracts/recomendacion_service.dart';

class RecomendacionServiceApi implements RecomendacionService {
  RecomendacionServiceApi(this._api, this._auth);
  final ApiClient _api;
  final AuthService _auth;
  @override
  Future<List<RubroDto>> rubros() async =>
      (await _api.getJson('api/rubros') as List)
          .map((j) => RubroDto.fromJson(j as Map<String, dynamic>))
          .toList();
  @override
  Future<PaginaDto<RecomendacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async => PaginaDto.fromJson(
    await _api.getJson(
      'api/recomendaciones',
      query: {...filtros, 'pagina': '$pagina', 'tamanoPagina': '20'},
    ) as Map<String, dynamic>,
    RecomendacionDto.fromJson,
  );
  @override
  Future<RecomendacionDto> detalle(String id) async =>
      RecomendacionDto.fromJson(
        await _api.getJson('api/recomendaciones/$id') as Map<String, dynamic>,
      );
  @override
  Future<List<PrestadorDto>> similares({
    required String nombre,
    required String rubroId,
    required String localidadId,
  }) async =>
      (await _api.getJson(
            'api/prestadores/similares',
            query: {
              'nombre': nombre,
              'rubroId': rubroId,
              'localidadId': localidadId,
            },
          ) as List)
          .map((j) => PrestadorDto.fromJson(j as Map<String, dynamic>))
          .toList();
  @override
  Future<RecomendacionDto> crear(CrearRecomendacionRequest request) async =>
      RecomendacionDto.fromJson(
        await _auth.postProtegido('api/recomendaciones', request.toJson())
            as Map<String, dynamic>,
      );
}
