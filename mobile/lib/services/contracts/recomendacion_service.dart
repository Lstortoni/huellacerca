import '../../models/pagina_dto.dart';
import '../../models/recomendacion_dto.dart';

abstract class RecomendacionService {
  Future<List<RubroDto>> rubros();
  Future<List<AspectoDto>> aspectos();
  Future<PaginaDto<PrestadorDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  });
  Future<PrestadorDto> detalle(String id);
  Future<PaginaDto<MascoteroRecomiendaDto>> recomendadores(
    String prestadorId, {
    int pagina = 1,
  });
  Future<RecomendacionDto?> miRecomendacion(String prestadorId);
  Future<List<PrestadorDto>> similares({
    required String nombre,
    required String rubroId,
    required String localidadId,
  });
  Future<RecomendacionDto> crear(CrearRecomendacionRequest request);
  Future<RecomendacionDto> guardarAspectos(String id, List<String> aspectoIds);
  Future<void> retirar(String id);

  /// Abren la app de teléfono o WhatsApp; false si no hay app disponible.
  Future<bool> llamar(String telefono);
  Future<bool> escribirPorWhatsApp(String telefono, String mensaje);
}
