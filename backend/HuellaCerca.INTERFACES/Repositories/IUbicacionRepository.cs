using HuellaCerca.MODEL;

namespace HuellaCerca.INTERFACES.Repositories;

public interface IUbicacionRepository
{
    Task<IReadOnlyList<Pais>> GetPaisesAsync(CancellationToken ct);
    Task<IReadOnlyList<Provincia>> GetProvinciasAsync(string paisCodigo, CancellationToken ct);
    Task<bool> ProvinciaActivaExisteAsync(Guid id, CancellationToken ct);
    Task<Localidad?> GetLocalidadActivaAsync(Guid id, CancellationToken ct);
    /// Sin provinciaId busca en todo el país.
    Task<(IReadOnlyList<Localidad> Items, int Total)> GetLocalidadesAsync(Guid? provinciaId, string? busqueda, int pagina, int tamanoPagina, CancellationToken ct);
}

