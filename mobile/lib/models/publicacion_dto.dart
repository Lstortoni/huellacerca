const tiposPublicacion = {
  1: 'Perdí una mascota',
  2: 'Encontré una mascota',
  3: 'Doy en adopción',
  4: 'Busco adoptar',
};
// En búsqueda hablamos de los avisos de otras personas, no de la acción del lector.
const tiposPublicacionBusqueda = {
  1: 'Perdidas',
  2: 'Encontradas',
  3: 'En adopción',
  4: 'Buscan adoptar',
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
// Emoji porque Material no tiene ícono de gato; se ven bien en Android sin paquetes.
const iconosMascota = {1: '🐶', 2: '🐱', 3: '🐾'};
const estadosPublicacion = {1: 'Activa', 2: 'Resuelta'};

class CoincidenciaPublicacionDto {
  CoincidenciaPublicacionDto.fromJson(Map<String, dynamic> j)
    : publicacion = PublicacionDto.fromJson(
        j['publicacion'] as Map<String, dynamic>,
      ),
      coincideEn = (j['coincideEn'] as List).cast<String>();
  final PublicacionDto publicacion;
  final List<String> coincideEn;
}

class OpcionCaracteristicaDto {
  OpcionCaracteristicaDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      nombre = j['nombre'] as String;
  final int id;
  final String nombre;
}

class CaracteristicaMascotaDto {
  CaracteristicaMascotaDto.fromJson(Map<String, dynamic> j)
    : campo = j['campo'] as String,
      nombre = j['nombre'] as String,
      opciones = (j['opciones'] as List)
          .map(
            (o) => OpcionCaracteristicaDto.fromJson(o as Map<String, dynamic>),
          )
          .toList();
  final String campo, nombre;
  final List<OpcionCaracteristicaDto> opciones;
}

class PublicacionDto {
  PublicacionDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      mascoteroId = j['mascoteroId'] as String,
      autor = j['autor'] as String,
      tipoPublicacion = j['tipoPublicacion'] as int,
      tipoMascota = j['tipoMascota'] as int,
      tamano = j['tamano'] as int?,
      raza = j['raza'] as int?,
      pelaje = j['pelaje'] as int?,
      colorPredominante = j['colorPredominante'] as int?,
      colorOjos = j['colorOjos'] as int?,
      fotoUrl = (j['foto'] as Map<String, dynamic>?)?['url'] as String?,
      nombreMascota = j['nombreMascota'] as String?,
      descripcion = j['descripcion'] as String,
      fechaSuceso = j['fechaSuceso'] == null
          ? null
          : DateTime.parse(j['fechaSuceso'] as String),
      fechaCreacion = DateTime.parse(j['fechaCreacion'] as String),
      localidadId = j['localidadId'] as String,
      localidad = j['localidad'] as String,
      provinciaId = j['provinciaId'] as String,
      provincia = j['provincia'] as String,
      version = j['version'] as String,
      fechaActualizacion = j['fechaActualizacion'] == null
          ? null
          : DateTime.parse(j['fechaActualizacion'] as String),
      zona = j['zona'] as String,
      informacionContacto = j['informacionContacto'] as String,
      estado = j['estado'] as int;
  final String id,
      mascoteroId,
      autor,
      descripcion,
      localidadId,
      localidad,
      provinciaId,
      provincia,
      zona,
      informacionContacto;

  /// Token de concurrencia: se envía al editar; la API rechaza versiones viejas.
  final String version;
  final DateTime? fechaActualizacion;
  final String? nombreMascota;
  final String? fotoUrl;
  final int tipoPublicacion, tipoMascota, estado;
  final int? tamano, raza, pelaje, colorPredominante, colorOjos;
  final DateTime? fechaSuceso;
  final DateTime fechaCreacion;
  Map<String, int> get caracteristicas => {
    'tamano': ?tamano,
    'raza': ?raza,
    'pelaje': ?pelaje,
    'colorPredominante': ?colorPredominante,
    'colorOjos': ?colorOjos,
  };
  DateTime get fechaReferencia => tipoPublicacion >= 3 || fechaSuceso == null
      ? fechaCreacion.toUtc().subtract(const Duration(hours: 3))
      : fechaSuceso!;
  String get etiquetaFecha =>
      tipoPublicacion >= 3 ? 'Publicado' : 'Fecha del suceso';
  String get titulo => nombreMascota ?? tiposMascota[tipoMascota] ?? 'Mascota';

  /// Texto listo para difundir por WhatsApp u otras apps.
  String get textoParaCompartir {
    final encabezado = switch (tipoPublicacion) {
      1 => '🔍 MASCOTA PERDIDA',
      2 => '📍 MASCOTA ENCONTRADA',
      3 => '💜 EN ADOPCIÓN',
      _ => '🏠 BUSCA ADOPTAR',
    };
    final especie = tiposMascota[tipoMascota] ?? 'Mascota';
    return [
      nombreMascota == null
          ? '$encabezado: $especie'
          : '$encabezado: $nombreMascota ($especie)',
      '📍 $localidad, $provincia${zona.isEmpty ? '' : ' · $zona'}',
      '📅 $resumenFecha (${fechaVisible(fechaReferencia)})',
      '',
      descripcion,
      '',
      '📞 Contacto: $informacionContacto',
      '',
      'Publicado en Huella Cerca 🐾',
    ].join('\n');
  }

  /// Ej.: "Se perdió hace 3 días", "Publicado hoy".
  String get resumenFecha {
    final cuando = fechaRelativa(fechaReferencia);
    return switch (tipoPublicacion) {
      1 => 'Se perdió $cuando',
      2 => 'Se encontró $cuando',
      _ => 'Publicado $cuando',
    };
  }
}

String fechaApi(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
String fechaVisible(DateTime fecha) =>
    '${fecha.day}/${fecha.month}/${fecha.year}';

/// Compara solo el día: "hoy", "ayer", "hace N días" o "el D/M/AAAA" desde 30 días.
String fechaRelativa(DateTime fecha, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  final dias = DateTime.utc(
    hoy.year,
    hoy.month,
    hoy.day,
  ).difference(DateTime.utc(fecha.year, fecha.month, fecha.day)).inDays;
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 30) return 'hace $dias días';
  return 'el ${fechaVisible(fecha)}';
}

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
    this.tamano,
    this.raza,
    this.pelaje,
    this.colorPredominante,
    this.colorOjos,
  });
  final int tipoPublicacion, tipoMascota;
  final int? tamano, raza, pelaje, colorPredominante, colorOjos;
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
    if (tamano != null) 'tamano': tamano,
    if (raza != null) 'raza': raza,
    if (pelaje != null) 'pelaje': pelaje,
    if (colorPredominante != null) 'colorPredominante': colorPredominante,
    if (colorOjos != null) 'colorOjos': colorOjos,
  };
}

/// Cuerpo del PUT. La API rechaza campos desconocidos: no incluye el tipo de
/// aviso (no se puede cambiar) y sí la [version] recibida en el detalle.
/// Las características se envían siempre: null borra el valor anterior.
class EditarPublicacionRequest {
  const EditarPublicacionRequest({
    required this.tipoPublicacion,
    required this.version,
    required this.tipoMascota,
    this.nombreMascota,
    required this.descripcion,
    this.fechaSuceso,
    required this.localidadId,
    required this.zona,
    required this.informacionContacto,
    this.tamano,
    this.raza,
    this.pelaje,
    this.colorPredominante,
    this.colorOjos,
  });

  /// Solo decide qué campos aplican; no se envía.
  final int tipoPublicacion;
  final String version;
  final int tipoMascota;
  final int? tamano, raza, pelaje, colorPredominante, colorOjos;
  final String? nombreMascota;
  final String descripcion, localidadId, zona, informacionContacto;
  final DateTime? fechaSuceso;
  Map<String, Object?> toJson() => {
    'version': version,
    'tipoMascota': tipoMascota,
    'nombreMascota': tipoPublicacion == 4 ? null : nombreMascota,
    'descripcion': descripcion,
    'fechaSuceso': tipoPublicacion <= 2 && fechaSuceso != null
        ? fechaApi(fechaSuceso!)
        : null,
    'localidadId': localidadId,
    'zona': zona,
    'informacionContacto': informacionContacto,
    'tamano': tamano,
    'raza': raza,
    'pelaje': pelaje,
    'colorPredominante': colorPredominante,
    'colorOjos': colorOjos,
  };
}
