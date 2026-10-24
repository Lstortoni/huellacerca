namespace HuellaCerca.CONTRACT.Ubicacion;

public sealed record PaisDto(string Codigo, string Nombre);
public sealed record ProvinciaDto(Guid Id, string Nombre, string PaisCodigo);
// Provincia (nombre) distingue localidades homónimas al buscar en todo el país.
public sealed record LocalidadDto(Guid Id, string Nombre, Guid ProvinciaId, string Provincia);
public sealed record PaginaDto<T>(IReadOnlyList<T> Items, int Total, int Pagina, int TamanoPagina);

