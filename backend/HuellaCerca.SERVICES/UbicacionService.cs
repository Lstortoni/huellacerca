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
        var busqueda = query.Busqueda?.Trim();
        if (query.ProvinciaId == Guid.Empty || (query.ProvinciaId is null && (busqueda?.Length ?? 0) < 2))
            throw new ArgumentException("Indicá una provincia o al menos 2 letras de búsqueda.");
        if (query.ProvinciaId is { } provincia && !await repository.ProvinciaActivaExisteAsync(provincia, ct))
            return null;
        var (items, total) = await repository.GetLocalidadesAsync(query.ProvinciaId,
            busqueda, query.Pagina, query.TamanoPagina, ct);
        return new(items.Select(ToDto).ToList(), total, query.Pagina, query.TamanoPagina);
    }

    public async Task<LocalidadDto?> GetLocalidadAsync(Guid id, CancellationToken ct) =>
        await repository.GetLocalidadActivaAsync(id, ct) is { } localidad ? ToDto(localidad) : null;

    private static LocalidadDto ToDto(HuellaCerca.MODEL.Localidad x) =>
        new(x.Id, x.Nombre, x.ProvinciaId, x.Provincia.Nombre);
}

