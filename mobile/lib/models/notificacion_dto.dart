import 'publicacion_dto.dart';

/// Resumen de un aviso con su estado actual, tal como lo devuelve la API.
class PublicacionResumenDto {
  PublicacionResumenDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      tipoPublicacion = j['tipoPublicacion'] as int,
      tipoMascota = j['tipoMascota'] as int,
      nombreMascota = j['nombreMascota'] as String?,
      localidad = j['localidad'] as String,
      estado = j['estado'] as int,
      fotoUrl = j['fotoUrl'] as String?;
  final String id, localidad;
  final int tipoPublicacion, tipoMascota, estado;
  final String? nombreMascota, fotoUrl;
  String get titulo => nombreMascota ?? tiposMascota[tipoMascota] ?? 'Mascota';
}

/// Posible coincidencia entre un aviso propio ([publicacion]) y otro ([coincidente]).
class NotificacionDto {
  NotificacionDto.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      titulo = j['titulo'] as String,
      mensaje = j['mensaje'] as String,
      fechaCreacion = DateTime.parse(j['fechaCreacion'] as String),
      fechaLectura = j['fechaLectura'] == null
          ? null
          : DateTime.parse(j['fechaLectura'] as String),
      publicacion = PublicacionResumenDto.fromJson(
        j['publicacion'] as Map<String, dynamic>,
      ),
      coincidente = PublicacionResumenDto.fromJson(
        j['coincidente'] as Map<String, dynamic>,
      );
  final String id, titulo, mensaje;
  final DateTime fechaCreacion;
  final DateTime? fechaLectura;
  final PublicacionResumenDto publicacion, coincidente;
  bool get leida => fechaLectura != null;
}
