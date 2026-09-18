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
  Future<PaginaDto<MascoteroRecomiendaDto>> recomendadores(
    String prestadorId, {
    int pagina = 1,
  }) async => PaginaDto.fromJson(
    await _api.getJson(
      'api/prestadores/$prestadorId/recomendadores',
      query: {'pagina': '$pagina', 'tamanoPagina': '20'},
    ) as Map<String, dynamic>,
    MascoteroRecomiendaDto.fromJson,
  );
  @override
  Future<List<RubroDto>> rubros() async =>
      (await _api.getJson('api/rubros') as List)
          .map((j) => RubroDto.fromJson(j as Map<String, dynamic>))
          .toList();
  @override
  Future<List<AspectoDto>> aspectos() async =>
      (await _api.getJson('api/aspectos-recomendacion') as List)
          .map((j) => AspectoDto.fromJson(j as Map<String, dynamic>))
          .toList();
  @override
  Future<PaginaDto<PrestadorDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async => PaginaDto.fromJson(
    await _api.getJson(
      'api/prestadores',
      query: {...filtros, 'pagina': '$pagina', 'tamanoPagina': '20'},
    ) as Map<String, dynamic>,
    PrestadorDto.fromJson,
  );
  @override
  Future<PrestadorDto> detalle(String id) async => PrestadorDto.fromJson(
    await _api.getJson('api/prestadores/$id') as Map<String, dynamic>,
  );
  @override
  Future<RecomendacionDto?> miRecomendacion(String prestadorId) async {
    final path = Uri(
      path: 'api/recomendaciones/mias',
      queryParameters: {'prestadorServicioId': prestadorId},
    ).toString();
    final data = await _auth.getProtegido(path) as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.isEmpty
        ? null
        : RecomendacionDto.fromJson(items.first as Map<String, dynamic>);
  }

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
  @override
  Future<RecomendacionDto> guardarAspectos(
    String id,
    List<String> aspectoIds,
  ) async => RecomendacionDto.fromJson(
    await _auth.putProtegido('api/recomendaciones/$id/aspectos', {
      'aspectoIds': aspectoIds,
    }) as Map<String, dynamic>,
  );
  @override
  Future<void> retirar(String id) =>
      _auth.deleteProtegido('api/recomendaciones/$id');
}
