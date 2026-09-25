import '../../core/network/api_client.dart';
import '../../core/util/contacto.dart';
import '../contracts/acciones_externas.dart';
import '../../models/pagina_dto.dart';
import '../../models/publicacion_dto.dart';
import '../contracts/auth_service.dart';
import '../contracts/publicacion_service.dart';
import '../contracts/selector_fotos.dart';
import '../../models/foto_seleccionada.dart';

class PublicacionServiceApi implements PublicacionService {
  PublicacionServiceApi(
    this._api,
    this._auth, [
    this._selector,
    this._acciones,
  ]);
  final SelectorFotos? _selector;
  final AccionesExternas? _acciones;
  @override
  Future<void> compartir(PublicacionDto p) async => _acciones?.compartir(
    p.textoParaCompartir,
    urlImagen: p.fotoUrl == null ? null : urlFoto(p.fotoUrl!),
  );
  @override
  Future<bool> llamar(String telefono) async =>
      await _acciones?.abrir(uriLlamada(telefono)) ?? false;
  @override
  Future<bool> escribirPorWhatsApp(String telefono, String mensaje) async =>
      await _acciones?.abrir(uriWhatsApp(telefono, mensaje)) ?? false;
  @override
  Future<FotoSeleccionada?> elegirFoto() async => _selector?.elegir();
  @override
  Future<FotoSeleccionada?> recuperarFoto() async => _selector?.recuperar();
  @override
  Future<void> subirFoto(String id, FotoSeleccionada foto) async {
    await _auth.subirFotoProtegida('api/publicaciones/$id/foto', foto.bytes);
  }

  @override
  Future<void> eliminarFoto(String id) =>
      _auth.deleteProtegido('api/publicaciones/$id/foto');
  @override
  String urlFoto(String path) => _api.resolverUrl(path);
  final ApiClient _api;
  final AuthService _auth;
  @override
  Future<PaginaDto<CoincidenciaPublicacionDto>> coincidencias(
    String id, {
    int pagina = 1,
    int tamanoPagina = 10,
  }) async => PaginaDto.fromJson(
    await _auth.getProtegido(
      'api/publicaciones/$id/coincidencias?pagina=$pagina&tamanoPagina=$tamanoPagina',
    ) as Map<String, dynamic>,
    CoincidenciaPublicacionDto.fromJson,
  );
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
  Future<PublicacionDto> editar(
    String id,
    EditarPublicacionRequest request,
  ) async => PublicacionDto.fromJson(
    await _auth.putProtegido('api/publicaciones/$id', request.toJson())
        as Map<String, dynamic>,
  );
  @override
  Future<PublicacionDto> reabrir(String id) async => PublicacionDto.fromJson(
    await _auth.patchProtegido('api/publicaciones/$id/reabrir')
        as Map<String, dynamic>,
  );
  @override
  Future<PublicacionDto> resolver(String id) async => PublicacionDto.fromJson(
    await _auth.patchProtegido('api/publicaciones/$id/resolver')
        as Map<String, dynamic>,
  );
}
