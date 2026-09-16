import '../../models/pagina_dto.dart';
import '../../models/recomendacion_dto.dart';

abstract class RecomendacionService {
  Future<List<RubroDto>> rubros();
  Future<PaginaDto<RecomendacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  });
  Future<RecomendacionDto> detalle(String id);
  Future<List<PrestadorDto>> similares({
    required String nombre,
    required String rubroId,
    required String localidadId,
  });
  Future<RecomendacionDto> crear(CrearRecomendacionRequest request);
}
