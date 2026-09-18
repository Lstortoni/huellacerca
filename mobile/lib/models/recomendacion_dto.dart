class MascoteroRecomiendaDto {
  MascoteroRecomiendaDto.fromJson(Map<String, dynamic> j)
    : nombre = j['nombre'] as String;
  final String nombre;
}

class RubroDto {
  RubroDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String;
  final String id, nombre;
}

class AspectoDto {
  AspectoDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String,
      activo = j['activo'] as bool;
  final String id, nombre;
  final bool activo;
}

class AspectoConteoDto {
  AspectoConteoDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String,
      cantidad = j['cantidad'] as int;
  final String id, nombre;
  final int cantidad;
}

class PrestadorDto {
  PrestadorDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      nombre = j['nombre'] as String,
      rubro = j['rubro'] as String,
      localidad = j['localidad'] as String,
      direccion = j['direccion'] as String?,
      telefono = j['telefono'] as String?,
      enlace = j['enlace'] as String?,
      totalRecomendaciones = j['totalRecomendaciones'] as int,
      aspectos = (j['aspectos'] as List)
          .map((a) => AspectoConteoDto.fromJson(a as Map<String, dynamic>))
          .toList();
  final String id, nombre, rubro, localidad;
  final String? direccion, telefono, enlace;
  final int totalRecomendaciones;
  final List<AspectoConteoDto> aspectos;
  String get textoRecomendaciones => totalRecomendaciones == 1
      ? '1 persona lo recomienda'
      : '$totalRecomendaciones personas lo recomiendan';
}

class RecomendacionDto {
  RecomendacionDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      prestador = PrestadorDto.fromJson(j['prestador'] as Map<String, dynamic>),
      aspectos = (j['aspectos'] as List)
          .map((a) => AspectoDto.fromJson(a as Map<String, dynamic>))
          .toList();
  final String id;
  final PrestadorDto prestador;
  final List<AspectoDto> aspectos;
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
    this.prestadorServicioId,
    this.nuevoPrestador,
  });
  final String? prestadorServicioId;
  final NuevoPrestadorRequest? nuevoPrestador;
  Map<String, Object?> toJson() => {
    if (prestadorServicioId != null) 'prestadorServicioId': prestadorServicioId,
    if (nuevoPrestador != null) 'nuevoPrestador': nuevoPrestador!.toJson(),
  };
}
