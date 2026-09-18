using System.ComponentModel.DataAnnotations;
using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;

namespace HuellaCerca.SERVICES;

public sealed class PublicacionService(IPublicacionRepository repository, IAuthRepository ubicaciones) : IPublicacionService
{
    public async Task<PublicacionDto> CrearAsync(Guid mascoteroId, CrearPublicacionRequest request, CancellationToken ct)
    {
        Validar(request);
        if (request.Descripcion.Trim().Length < 10)
            throw new AppException(400, "Describí la mascota y lo sucedido en al menos 10 caracteres.");
        // FechaSuceso no contiene hora; se compara con el día actual en Argentina.
        var hoy = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "America/Argentina/Buenos_Aires"));
        var requiereFecha = request.TipoPublicacion is 1 or 2;
        if (requiereFecha && (request.FechaSuceso is null || request.FechaSuceso == DateOnly.MinValue || request.FechaSuceso > hoy))
            throw new AppException(400, "Indicá una fecha del suceso válida, que no sea futura.");
        if (request.TipoPublicacion != 4 && string.IsNullOrWhiteSpace(request.Zona))
            throw new AppException(400, "Indicá la zona aproximada.");
        if (!await ubicaciones.LocalidadActivaAsync(request.LocalidadId, ct))
            throw new AppException(400, "Seleccioná una localidad activa.");

        var publicacion = new PublicacionMascota
        {
            MascoteroId = mascoteroId,
            TipoPublicacion = (TipoPublicacionMascota)request.TipoPublicacion,
            TipoMascota = (TipoMascota)request.TipoMascota,
            NombreMascota = request.TipoPublicacion == 4 || string.IsNullOrWhiteSpace(request.NombreMascota) ? null : request.NombreMascota.Trim(),
            Descripcion = request.Descripcion.Trim(),
            FechaSuceso = requiereFecha ? request.FechaSuceso : null,
            LocalidadId = request.LocalidadId,
            Zona = request.Zona?.Trim() ?? "",
            InformacionContacto = request.InformacionContacto.Trim()
        };
        repository.Agregar(publicacion);
        await repository.GuardarAsync(ct);
        return await PorIdAsync(publicacion.Id, ct);
    }

    public async Task<PublicacionDto> PorIdAsync(Guid id, CancellationToken ct) => ToDto(await ObtenerAsync(id, ct));

    public async Task<PaginaDto<PublicacionDto>> BuscarAsync(PublicacionesQuery query, CancellationToken ct)
    {
        Validar(query);
        var (items, total) = await repository.BuscarAsync(query, ct);
        return new(items.Select(ToDto).ToList(), total, query.Pagina, query.TamanoPagina);
    }

    public async Task<PublicacionDto> ResolverAsync(Guid id, Guid mascoteroId, CancellationToken ct)
    {
        var publicacion = await ObtenerAsync(id, ct);
        if (publicacion.MascoteroId != mascoteroId)
            throw new AppException(403, "Solo el autor puede resolver esta publicación.");
        if (publicacion.Estado != EstadoPublicacionMascota.Resuelta)
        {
            publicacion.Estado = EstadoPublicacionMascota.Resuelta;
            await repository.GuardarAsync(ct);
        }
        return ToDto(publicacion);
    }

    private async Task<PublicacionMascota> ObtenerAsync(Guid id, CancellationToken ct) =>
        await repository.PorIdAsync(id, ct) ?? throw new AppException(404, "Publicación no encontrada.");

    private static void Validar(object request)
    {
        var errores = new List<ValidationResult>();
        if (!Validator.TryValidateObject(request, new ValidationContext(request), errores, true))
            throw new AppException(400, errores[0].ErrorMessage ?? "Datos inválidos.");
    }

    private static PublicacionDto ToDto(PublicacionMascota p) => new(p.Id, p.MascoteroId, p.Mascotero.Nombre,
        (int)p.TipoPublicacion, (int)p.TipoMascota, p.NombreMascota, p.Descripcion, p.FechaSuceso,
        p.LocalidadId, p.Localidad.Nombre, p.Localidad.ProvinciaId, p.Localidad.Provincia.Nombre,
        p.Zona, p.InformacionContacto, p.FechaCreacion, (int)p.Estado,
        p.Fotografias.OrderBy(x => x.Orden).Select(x => new FotoPublicacionDto(x.Id, x.Orden)).ToList());
}
