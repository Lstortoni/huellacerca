using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.SERVICES;

public sealed class UbicacionService(IUbicacionRepository repository) : IUbicacionService
{
    public async Task<IReadOnlyList<PaisDto>> GetPaisesAsync(CancellationToken ct) =>
        (await repository.GetPaisesAsync(ct)).Select(x => new PaisDto(x.Codigo, x.Nombre)).ToList();

    public async Task<IReadOnlyList<ProvinciaDto>> GetProvinciasAsync(string paisCodigo, CancellationToken ct) =>
        (await repository.GetProvinciasAsync(paisCodigo.Trim().ToUpperInvariant(), ct))
        .Select(x => new ProvinciaDto(x.Id, x.Nombre, x.PaisCodigo)).ToList();

    public async Task<PaginaDto<LocalidadDto>?> GetLocalidadesAsync(LocalidadesQuery query, CancellationToken ct)
    {
        if (query.ProvinciaId is null || query.ProvinciaId == Guid.Empty)
            throw new ArgumentException("La provincia es obligatoria.");
        if (!await repository.ProvinciaActivaExisteAsync(query.ProvinciaId.Value, ct)) return null;
        var (items, total) = await repository.GetLocalidadesAsync(query.ProvinciaId.Value,
            query.Busqueda?.Trim(), query.Pagina, query.TamanoPagina, ct);
        return new(items.Select(x => new LocalidadDto(x.Id, x.Nombre, x.ProvinciaId)).ToList(),
            total, query.Pagina, query.TamanoPagina);
    }
}

