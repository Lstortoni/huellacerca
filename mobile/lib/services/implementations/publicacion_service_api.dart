import '../../core/network/api_client.dart';
import '../../models/pagina_dto.dart';
import '../../models/publicacion_dto.dart';
import '../contracts/auth_service.dart';
import '../contracts/publicacion_service.dart';

class PublicacionServiceApi implements PublicacionService {
  PublicacionServiceApi(this._api, this._auth);
  final ApiClient _api;
  final AuthService _auth;
  @override
  Future<PaginaDto<CoincidenciaPublicacionDto>> coincidencias(String id, {int pagina = 1, int tamanoPagina = 10}) async =>
    PaginaDto.fromJson(await _auth.getProtegido('api/publicaciones/$id/coincidencias?pagina=$pagina&tamanoPagina=$tamanoPagina') as Map<String, dynamic>, CoincidenciaPublicacionDto.fromJson);
  @override
  Future<List<CaracteristicaMascotaDto>> caracteristicas(
    int tipoMascota,
  ) async =>
      (await _api.getJson(
            'api/publicaciones/caracteristicas',
            query: {'tipoMascota': '$tipoMascota'},
          ) as List)
          .map(
            (j) => CaracteristicaMascotaDto.fromJson(j as Map<String, dynamic>),
          )
          .toList();
  @override
  Future<PaginaDto<PublicacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async => PaginaDto.fromJson(
    await _api.getJson(
      'api/publicaciones',
      query: {...filtros, 'pagina': '$pagina', 'tamanoPagina': '20'},
    ) as Map<String, dynamic>,
    PublicacionDto.fromJson,
  );
  @override
  Future<PublicacionDto> detalle(String id) async => PublicacionDto.fromJson(
    await _api.getJson('api/publicaciones/$id') as Map<String, dynamic>,
  );
  @override
  Future<PublicacionDto> crear(CrearPublicacionRequest request) async =>
      PublicacionDto.fromJson(
        await _auth.postProtegido('api/publicaciones', request.toJson())
            as Map<String, dynamic>,
      );
  @override
  Future<PublicacionDto> resolver(String id) async => PublicacionDto.fromJson(
    await _auth.patchProtegido('api/publicaciones/$id/resolver')
        as Map<String, dynamic>,
  );
}
