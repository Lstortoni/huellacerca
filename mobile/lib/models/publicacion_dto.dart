const tiposPublicacion = {1: 'Perdida', 2: 'Encontrada'};
const tiposMascota = {1: 'Perro', 2: 'Gato', 3: 'Otro'};
const estadosPublicacion = {1: 'Activa', 2: 'Resuelta'};

class PublicacionDto {
  PublicacionDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      mascoteroId = j['mascoteroId'] as String,
      autor = j['autor'] as String,
      tipoPublicacion = j['tipoPublicacion'] as int,
      tipoMascota = j['tipoMascota'] as int,
      nombreMascota = j['nombreMascota'] as String?,
      descripcion = j['descripcion'] as String,
      fechaSuceso = DateTime.parse(j['fechaSuceso'] as String),
      localidad = j['localidad'] as String,
      provincia = j['provincia'] as String,
      zona = j['zona'] as String,
      informacionContacto = j['informacionContacto'] as String,
      estado = j['estado'] as int;
  final String id,
      mascoteroId,
      autor,
      descripcion,
      localidad,
      provincia,
      zona,
      informacionContacto;
  final String? nombreMascota;
  final int tipoPublicacion, tipoMascota, estado;
  final DateTime fechaSuceso;
  String get titulo => nombreMascota ?? tiposMascota[tipoMascota] ?? 'Mascota';
}

String fechaApi(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
String fechaVisible(DateTime fecha) =>
    '${fecha.day}/${fecha.month}/${fecha.year}';

class CrearPublicacionRequest {
  const CrearPublicacionRequest({
    required this.tipoPublicacion,
    required this.tipoMascota,
    this.nombreMascota,
    required this.descripcion,
    required this.fechaSuceso,
    required this.localidadId,
    required this.zona,
    required this.informacionContacto,
  });
  final int tipoPublicacion, tipoMascota;
  final String? nombreMascota;
  final String descripcion, localidadId, zona, informacionContacto;
  final DateTime fechaSuceso;
  Map<String, Object?> toJson() => {
    'tipoPublicacion': tipoPublicacion,
    'tipoMascota': tipoMascota,
    'nombreMascota': nombreMascota,
    'descripcion': descripcion,
    'fechaSuceso': fechaApi(fechaSuceso),
    'localidadId': localidadId,
    'zona': zona,
    'informacionContacto': informacionContacto,
  };
}
