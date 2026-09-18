using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;
namespace HuellaCerca.SERVICES;

public sealed class RecomendacionService(IRecomendacionRepository repository, IAuthRepository usuarios) : IRecomendacionService
{
    public async Task<IReadOnlyList<RubroDto>> RubrosAsync(CancellationToken ct) =>
        (await repository.RubrosAsync(ct)).Select(x => new RubroDto(x.Id, x.Nombre)).ToList();
    public async Task<IReadOnlyList<AspectoDto>> AspectosAsync(CancellationToken ct) =>
        (await repository.AspectosAsync(ct)).Select(x => new AspectoDto(x.Id, x.Nombre, x.Activo)).ToList();
    public async Task<IReadOnlyList<PrestadorDto>> SimilaresAsync(SimilaresQuery query, CancellationToken ct)
    {
        if (!await repository.RubroActivoAsync(query.RubroId, ct) || !await usuarios.LocalidadActivaAsync(query.LocalidadId, ct))
            throw new AppException(400, "Seleccioná rubro y localidad activos.");
        return await repository.SimilaresAsync(query, ct);
    }
    public async Task<PrestadorDto> PrestadorAsync(Guid id, CancellationToken ct)
    {
        _ = await repository.PrestadorAsync(id, ct) ?? throw new AppException(404, "Prestador no encontrado.");
        return (await repository.ResumenesAsync([id], ct)).Single();
    }
    public async Task<PaginaDto<PrestadorDto>> BuscarPrestadoresAsync(RecomendacionesQuery query, CancellationToken ct)
    {
        var (items, total) = await repository.BuscarPrestadoresAsync(query, ct);
        return new(items, total, query.Pagina, query.TamanoPagina);
    }
    public async Task<PaginaDto<MascoteroRecomiendaDto>> RecomendadoresAsync(Guid prestadorId, RecomendadoresQuery query, CancellationToken ct)
    {
        _ = await repository.PrestadorAsync(prestadorId, ct) ?? throw new AppException(404, "Prestador no encontrado.");
        var (items, total) = await repository.RecomendadoresAsync(prestadorId, query, ct);
        return new(items, total, query.Pagina, query.TamanoPagina);
    }
    public async Task<(RecomendacionDto Item, bool Creada)> CrearAsync(Guid mascoteroId, CrearRecomendacionRequest request, CancellationToken ct)
    {
        PrestadorServicio prestador;
        if (request.NuevoPrestador is { } nuevo)
        {
            if (!await repository.RubroActivoAsync(nuevo.RubroId, ct) || !await usuarios.LocalidadActivaAsync(nuevo.LocalidadId, ct))
                throw new AppException(400, "Seleccioná rubro y localidad activos.");
            if (!string.IsNullOrWhiteSpace(nuevo.Enlace) &&
                (!Uri.TryCreate(nuevo.Enlace, UriKind.Absolute, out var uri) || (uri.Scheme != "https" && uri.Scheme != "http") || string.IsNullOrWhiteSpace(uri.Host)))
                throw new AppException(400, "El enlace debe ser una URL HTTP o HTTPS.");
            prestador = new PrestadorServicio { Nombre = nuevo.Nombre.Trim(), RubroId = nuevo.RubroId,
                LocalidadId = nuevo.LocalidadId, MascoteroCreadorId = mascoteroId,
                Direccion = nuevo.Direccion?.Trim(), Telefono = nuevo.Telefono?.Trim(), Enlace = nuevo.Enlace?.Trim() };
        }
        else prestador = await repository.PrestadorAsync(request.PrestadorServicioId ?? Guid.Empty, ct)
            ?? throw new AppException(400, "Seleccioná un prestador activo.");
        var (item, creada) = await repository.CrearUnicaAsync(new Recomendacion {
            MascoteroId = mascoteroId, PrestadorServicio = prestador, PrestadorServicioId = prestador.Id }, ct);
        return (await ToDtoAsync(item, ct), creada);
    }
    public async Task<RecomendacionDto> PorIdAsync(Guid id, Guid mascoteroId, CancellationToken ct) =>
        await ToDtoAsync(await PropiaAsync(id, mascoteroId, ct), ct);
    public async Task<PaginaDto<RecomendacionDto>> MiasAsync(Guid mascoteroId, RecomendacionesQuery query, CancellationToken ct)
    {
        var (items, total) = await repository.MiasAsync(mascoteroId, query, ct);
        var prestadores = (await repository.ResumenesAsync(items.Select(x => x.PrestadorServicioId).Distinct().ToList(), ct)).ToDictionary(x => x.Id);
        return new(items.Select(x => ToDto(x, prestadores[x.PrestadorServicioId])).ToList(), total, query.Pagina, query.TamanoPagina);
    }
    public async Task<RecomendacionDto> EditarAsync(Guid id, Guid mascoteroId, EditarRecomendacionRequest request, CancellationToken ct)
    {
        var item = await PropiaAsync(id, mascoteroId, ct);
        var ids = request.AspectoIds.ToHashSet();
        var catalogo = await repository.AspectosAsync(ct);
        var permitidos = catalogo.Select(x => x.Id).Concat(item.Aspectos.Select(x => x.AspectoRecomendacionId)).ToHashSet();
        if (!ids.IsSubsetOf(permitidos)) throw new AppException(400, "Seleccioná aspectos disponibles del catálogo.");
        var actuales = item.Aspectos.Select(x => x.AspectoRecomendacionId).ToHashSet();
        if (actuales.SetEquals(ids)) return await ToDtoAsync(item, ct);
        foreach (var anterior in item.Aspectos.Where(x => !ids.Contains(x.AspectoRecomendacionId)).ToList()) item.Aspectos.Remove(anterior);
        foreach (var idAspecto in ids.Except(actuales))
            item.Aspectos.Add(new RecomendacionAspecto { RecomendacionId = item.Id, AspectoRecomendacionId = idAspecto });
        item.FechaActualizacion = DateTime.UtcNow;
        await repository.GuardarAsync(ct);
        return await ToDtoAsync(await repository.PorIdAsync(id, ct) ?? throw new AppException(404, "Recomendación no encontrada."), ct);
    }
    public async Task EliminarAsync(Guid id, Guid mascoteroId, CancellationToken ct)
    {
        repository.Eliminar(await PropiaAsync(id, mascoteroId, ct));
        await repository.GuardarAsync(ct);
    }
    private async Task<Recomendacion> PropiaAsync(Guid id, Guid mascoteroId, CancellationToken ct)
    {
        var item = await repository.PorIdAsync(id, ct) ?? throw new AppException(404, "Recomendación no encontrada.");
        if (item.MascoteroId != mascoteroId) throw new AppException(403, "Solo el autor puede modificar esta recomendación.");
        return item;
    }
    private async Task<RecomendacionDto> ToDtoAsync(Recomendacion r, CancellationToken ct) =>
        ToDto(r, (await repository.ResumenesAsync([r.PrestadorServicioId], ct)).Single());
    private static RecomendacionDto ToDto(Recomendacion r, PrestadorDto p) => new(r.Id, r.MascoteroId,
        r.FechaCreacion, r.FechaActualizacion, p, r.Aspectos.OrderBy(x => x.AspectoRecomendacionId)
            .Select(x => new AspectoDto(x.AspectoRecomendacionId, x.AspectoRecomendacion.Nombre, x.AspectoRecomendacion.Activo)).ToList());
}
