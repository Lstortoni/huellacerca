using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;

namespace HuellaCerca.SERVICES;

public sealed class RecomendacionService(IRecomendacionRepository repository, IAuthRepository usuarios) : IRecomendacionService
{
    public async Task<IReadOnlyList<RubroDto>> RubrosAsync(CancellationToken ct) => (await repository.RubrosAsync(ct)).Select(x => new RubroDto(x.Id, x.Nombre)).ToList();
    public async Task<IReadOnlyList<PrestadorDto>> SimilaresAsync(SimilaresQuery query, CancellationToken ct)
    {
        if (!await repository.RubroActivoAsync(query.RubroId, ct) || !await usuarios.LocalidadActivaAsync(query.LocalidadId, ct))
            throw new AppException(400, "Seleccioná rubro y localidad activos.");
        return (await repository.SimilaresAsync(query, ct)).Select(PrestadorDto).ToList();
    }
    public async Task<PrestadorDto> PrestadorAsync(Guid id, CancellationToken ct) => PrestadorDto(
        await repository.PrestadorAsync(id, ct) ?? throw new AppException(404, "Prestador no encontrado."));
    public async Task<RecomendacionDto> CrearAsync(Guid mascoteroId, CrearRecomendacionRequest request, CancellationToken ct)
    {
        PrestadorServicio prestador;
        if (request.NuevoPrestador is { } nuevo)
        {
            if (!await repository.RubroActivoAsync(nuevo.RubroId, ct) || !await usuarios.LocalidadActivaAsync(nuevo.LocalidadId, ct))
                throw new AppException(400, "Seleccioná rubro y localidad activos.");
            if (!string.IsNullOrWhiteSpace(nuevo.Enlace) &&
                (!Uri.TryCreate(nuevo.Enlace, UriKind.Absolute, out var uri) || (uri.Scheme != "https" && uri.Scheme != "http")))
                throw new AppException(400, "El enlace debe ser una URL HTTP o HTTPS.");
            prestador = new PrestadorServicio { Nombre = nuevo.Nombre.Trim(), RubroId = nuevo.RubroId,
                LocalidadId = nuevo.LocalidadId, MascoteroCreadorId = mascoteroId,
                Direccion = nuevo.Direccion?.Trim(), Telefono = nuevo.Telefono?.Trim(), Enlace = nuevo.Enlace?.Trim() };
        }
        else prestador = await repository.PrestadorAsync(request.PrestadorServicioId ?? Guid.Empty, ct)
            ?? throw new AppException(400, "Seleccioná un prestador activo.");
        var recomendacion = new Recomendacion { MascoteroId = mascoteroId, PrestadorServicio = prestador,
            PrestadorServicioId = prestador.Id, Titulo = request.Titulo.Trim(), Descripcion = request.Descripcion.Trim() };
        if (recomendacion.Descripcion.Length < 10) throw new AppException(400, "Contá tu experiencia en al menos 10 caracteres.");
        repository.Agregar(recomendacion);
        await repository.GuardarAsync(ct);
        return await PorIdAsync(recomendacion.Id, ct);
    }
    public async Task<RecomendacionDto> PorIdAsync(Guid id, CancellationToken ct) => ToDto(
        await repository.PorIdAsync(id, ct) ?? throw new AppException(404, "Recomendación no encontrada."));
    public async Task<PaginaDto<RecomendacionDto>> BuscarAsync(RecomendacionesQuery query, CancellationToken ct)
    {
        var (items, total) = await repository.BuscarAsync(query, ct);
        return new(items.Select(ToDto).ToList(), total, query.Pagina, query.TamanoPagina);
    }
    public async Task<RecomendacionDto> EditarAsync(Guid id, Guid mascoteroId, EditarRecomendacionRequest request, CancellationToken ct)
    {
        var item = await PropiaAsync(id, mascoteroId, ct);
        item.Titulo = request.Titulo.Trim();
        item.Descripcion = request.Descripcion.Trim();
        if (item.Descripcion.Length < 10) throw new AppException(400, "Contá tu experiencia en al menos 10 caracteres.");
        item.FechaActualizacion = DateTime.UtcNow;
        await repository.GuardarAsync(ct);
        return ToDto(item);
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
    private static PrestadorDto PrestadorDto(PrestadorServicio p) => new(p.Id, p.Nombre, p.RubroId, p.Rubro.Nombre,
        p.LocalidadId, p.Localidad.Nombre, p.Direccion, p.Telefono, p.Enlace);
    private static RecomendacionDto ToDto(Recomendacion r) => new(r.Id, r.MascoteroId, r.Mascotero.Nombre,
        r.Titulo, r.Descripcion, r.FechaCreacion, r.FechaActualizacion, PrestadorDto(r.PrestadorServicio));
}

