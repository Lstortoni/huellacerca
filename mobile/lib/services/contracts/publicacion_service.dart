import '../../models/pagina_dto.dart';
import '../../models/publicacion_dto.dart';
import '../../models/foto_seleccionada.dart';

abstract class PublicacionService {
  Future<FotoSeleccionada?> elegirFoto();
  Future<FotoSeleccionada?> recuperarFoto();
  Future<void> subirFoto(String id, FotoSeleccionada foto);
  Future<void> eliminarFoto(String id);
  String urlFoto(String path);
  Future<PaginaDto<CoincidenciaPublicacionDto>> coincidencias(
    String id, {
    int pagina = 1,
    int tamanoPagina = 10,
  });
  Future<List<CaracteristicaMascotaDto>> caracteristicas(int tipoMascota);
  Future<PaginaDto<PublicacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  });
  Future<PublicacionDto> detalle(String id);
  Future<PublicacionDto> crear(CrearPublicacionRequest request);
  Future<PublicacionDto> resolver(String id);
}
