namespace HuellaCerca.CONTRACT.Ubicacion;

public sealed record PaisDto(string Codigo, string Nombre);
public sealed record ProvinciaDto(Guid Id, string Nombre, string PaisCodigo);
public sealed record LocalidadDto(Guid Id, string Nombre, Guid ProvinciaId);
public sealed record PaginaDto<T>(IReadOnlyList<T> Items, int Total, int Pagina, int TamanoPagina);

