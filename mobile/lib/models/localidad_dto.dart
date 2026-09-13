class LocalidadDto {
  const LocalidadDto(this.id, this.nombre, this.provinciaId);
  final String id, nombre, provinciaId;
  factory LocalidadDto.fromJson(Map<String, dynamic> j) => LocalidadDto(
    j['id'] as String,
    j['nombre'] as String,
    j['provinciaId'] as String,
  );
}

class LocalidadesPagina {
  const LocalidadesPagina(this.items, this.total);
  final List<LocalidadDto> items;
  final int total;
}
