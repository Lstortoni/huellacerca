using HuellaCerca.CONTRACT.Ubicacion;

namespace HuellaCerca.INTERFACES.Services;

public interface IUbicacionService
{
    Task<IReadOnlyList<PaisDto>> GetPaisesAsync(CancellationToken ct);
    Task<IReadOnlyList<ProvinciaDto>> GetProvinciasAsync(string paisCodigo, CancellationToken ct);
    Task<PaginaDto<LocalidadDto>?> GetLocalidadesAsync(LocalidadesQuery query, CancellationToken ct);
    Task<LocalidadDto?> GetLocalidadAsync(Guid id, CancellationToken ct);
}

