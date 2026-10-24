import '../../models/provincia_dto.dart';
import '../../models/localidad_dto.dart';

/// Consultas de ubicación disponibles para las pantallas.
abstract class UbicacionService {
  Future<List<ProvinciaDto>> getProvincias();

  /// Sin [provinciaId] busca en todo el país (requiere al menos 2 letras).
  /// Primero devuelve las localidades que empiezan con [busqueda].
  Future<LocalidadesPagina> getLocalidades({
    String? provinciaId,
    String busqueda = '',
    int pagina = 1,
  });

  /// Nombre y provincia de una localidad (por ejemplo, la del perfil).
  Future<LocalidadDto> getLocalidad(String id);

  /// Últimas localidades elegidas en este teléfono, la más reciente primero.
  Future<List<LocalidadDto>> recientes();
  Future<void> recordar(LocalidadDto localidad);
}
