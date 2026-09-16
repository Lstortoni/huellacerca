class PaginaDto<T> {
  const PaginaDto(this.items, this.total, this.pagina, this.tamanoPagina);
  final List<T> items;
  final int total, pagina, tamanoPagina;
  bool get haySiguiente => pagina * tamanoPagina < total;
  factory PaginaDto.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) => PaginaDto(
    (j['items'] as List).map((x) => parse(x as Map<String, dynamic>)).toList(),
    j['total'] as int,
    j['pagina'] as int,
    j['tamanoPagina'] as int,
  );
}
