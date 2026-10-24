class LocalidadDto {
  const LocalidadDto(
    this.id,
    this.nombre,
    this.provinciaId, [
    this.provincia = '',
  ]);
  final String id, nombre, provinciaId;

  /// Nombre de la provincia: distingue localidades homónimas ("San Martín").
  final String provincia;

  /// "La Plata, Buenos Aires" (o solo el nombre si no se conoce la provincia).
  String get etiqueta => provincia.isEmpty ? nombre : '$nombre, $provincia';

  factory LocalidadDto.fromJson(Map<String, dynamic> j) => LocalidadDto(
    j['id'] as String,
    j['nombre'] as String,
    j['provinciaId'] as String,
    j['provincia'] as String? ?? '',
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'nombre': nombre,
    'provinciaId': provinciaId,
    'provincia': provincia,
  };
}

class LocalidadesPagina {
  const LocalidadesPagina(this.items, this.total);
  final List<LocalidadDto> items;
  final int total;
}

/// Resultado del selector: una localidad o, en filtros, una provincia entera.
class UbicacionElegida {
  const UbicacionElegida.localidad(LocalidadDto this.localidad)
    : provinciaId = '',
      provincia = '';
  const UbicacionElegida.provincia(this.provinciaId, this.provincia)
    : localidad = null;
  final LocalidadDto? localidad;
  final String provinciaId, provincia;

  String get idProvincia => localidad?.provinciaId ?? provinciaId;
  String get etiqueta =>
      localidad?.etiqueta ?? '$provincia (toda la provincia)';
}
