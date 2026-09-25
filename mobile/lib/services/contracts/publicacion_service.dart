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

  /// Solo el autor. Si el aviso cambió desde que se cargó, la API devuelve 409.
  Future<PublicacionDto> editar(String id, EditarPublicacionRequest request);

  /// Vuelve a activar un aviso resuelto y a buscar coincidencias.
  Future<PublicacionDto> reabrir(String id);

  /// Difunde el aviso con su texto y, si tiene, su foto.
  Future<void> compartir(PublicacionDto publicacion);

  /// Abren la app de teléfono o WhatsApp; false si no hay app disponible.
  Future<bool> llamar(String telefono);
  Future<bool> escribirPorWhatsApp(String telefono, String mensaje);
}
