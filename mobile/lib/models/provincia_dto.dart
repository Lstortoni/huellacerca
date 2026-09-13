/// Equivalente en Dart al ProvinciaDto que devuelve nuestra API C#.
class ProvinciaDto {
  const ProvinciaDto({
    required this.id,
    required this.nombre,
    required this.paisCodigo,
  });
  final String id;
  final String nombre;
  final String paisCodigo;

  factory ProvinciaDto.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['nombre'] is! String ||
        json['paisCodigo'] is! String) {
      throw const FormatException('Provincia incompleta.');
    }
    return ProvinciaDto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      paisCodigo: json['paisCodigo'] as String,
    );
  }
}
