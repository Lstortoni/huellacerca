const tiposPublicacion = {
  1: 'Perdí una mascota',
  2: 'Encontré una mascota',
  3: 'Doy en adopción',
  4: 'Busco adoptar',
};
// En búsqueda hablamos de los avisos de otras personas, no de la acción del lector.
const tiposPublicacionBusqueda = {
  1: 'Mascotas que su familia busca',
  2: 'Mascotas encontradas',
  3: 'Mascotas en adopción',
  4: 'Personas que quieren adoptar',
};
const explicacionesPublicacion = {
  1: 'Su familia publicó el aviso porque perdió a su mascota y quiere encontrarla.',
  2: 'Alguien encontró una mascota y publicó el aviso para localizar a su familia.',
  3: 'Personas que ofrecen un animal en adopción. Mirá estos avisos si querés adoptar.',
  4: 'Personas que buscan adoptar. Mirá estos avisos si tenés un animal para dar en adopción.',
};
const etiquetasPublicacion = {
  1: 'Perdida',
  2: 'Encontrada',
  3: 'En adopción',
  4: 'Busca adoptar',
};
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
      fechaSuceso = j['fechaSuceso'] == null
          ? null
          : DateTime.parse(j['fechaSuceso'] as String),
      fechaCreacion = DateTime.parse(j['fechaCreacion'] as String),
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
  final DateTime? fechaSuceso;
  final DateTime fechaCreacion;
  DateTime get fechaReferencia => tipoPublicacion >= 3 || fechaSuceso == null
      ? fechaCreacion.toUtc().subtract(const Duration(hours: 3))
      : fechaSuceso!;
  String get etiquetaFecha =>
      tipoPublicacion >= 3 ? 'Publicado' : 'Fecha del suceso';
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
    this.fechaSuceso,
    required this.localidadId,
    required this.zona,
    required this.informacionContacto,
  });
  final int tipoPublicacion, tipoMascota;
  final String? nombreMascota;
  final String descripcion, localidadId, zona, informacionContacto;
  final DateTime? fechaSuceso;
  Map<String, Object?> toJson() => {
    'tipoPublicacion': tipoPublicacion,
    'tipoMascota': tipoMascota,
    if (tipoPublicacion != 4) 'nombreMascota': nombreMascota,
    'descripcion': descripcion,
    if (tipoPublicacion <= 2 && fechaSuceso != null)
      'fechaSuceso': fechaApi(fechaSuceso!),
    'localidadId': localidadId,
    'zona': zona,
    'informacionContacto': informacionContacto,
  };
}
