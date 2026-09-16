class RubroDto {
  RubroDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String;
  final String id, nombre;
}

class PrestadorDto {
  PrestadorDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String,
      rubro = j['rubro'] as String,
      localidad = j['localidad'] as String,
      direccion = j['direccion'] as String?,
      telefono = j['telefono'] as String?,
      enlace = j['enlace'] as String?;
  final String id, nombre, rubro, localidad;
  final String? direccion, telefono, enlace;
}

class RecomendacionDto {
  RecomendacionDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      autor = j['autor'] as String,
      titulo = j['titulo'] as String,
      descripcion = j['descripcion'] as String,
      prestador = PrestadorDto.fromJson(j['prestador'] as Map<String, dynamic>);
  final String id, autor, titulo, descripcion;
  final PrestadorDto prestador;
}

class NuevoPrestadorRequest {
  const NuevoPrestadorRequest({
    required this.nombre,
    required this.rubroId,
    required this.localidadId,
    this.direccion,
    this.telefono,
    this.enlace,
  });
  final String nombre, rubroId, localidadId;
  final String? direccion, telefono, enlace;
  Map<String, Object?> toJson() => {
    'nombre': nombre,
    'rubroId': rubroId,
    'localidadId': localidadId,
    'direccion': direccion,
    'telefono': telefono,
    'enlace': enlace,
  };
}

class CrearRecomendacionRequest {
  const CrearRecomendacionRequest({
    required this.titulo,
    required this.descripcion,
    this.prestadorServicioId,
    this.nuevoPrestador,
  });
  final String titulo, descripcion;
  final String? prestadorServicioId;
  final NuevoPrestadorRequest? nuevoPrestador;
  Map<String, Object?> toJson() => {
    'titulo': titulo,
    'descripcion': descripcion,
    if (prestadorServicioId != null) 'prestadorServicioId': prestadorServicioId,
    if (nuevoPrestador != null) 'nuevoPrestador': nuevoPrestador!.toJson(),
  };
}
