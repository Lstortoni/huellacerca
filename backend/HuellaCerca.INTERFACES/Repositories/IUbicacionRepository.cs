using HuellaCerca.MODEL;

namespace HuellaCerca.INTERFACES.Repositories;

public interface IUbicacionRepository
{
    Task<IReadOnlyList<Pais>> GetPaisesAsync(CancellationToken ct);
    Task<IReadOnlyList<Provincia>> GetProvinciasAsync(string paisCodigo, CancellationToken ct);
    Task<bool> ProvinciaActivaExisteAsync(Guid id, CancellationToken ct);
    Task<(IReadOnlyList<Localidad> Items, int Total)> GetLocalidadesAsync(Guid provinciaId, string? busqueda, int pagina, int tamanoPagina, CancellationToken ct);
}

