import '../../models/provincia_dto.dart';
import '../../models/localidad_dto.dart';

/// Consultas de ubicación disponibles para las pantallas.
abstract class UbicacionService {
  Future<List<ProvinciaDto>> getProvincias();
  Future<LocalidadesPagina> getLocalidades(
    String provinciaId, {
    String busqueda = '',
    int pagina = 1,
  });
}
