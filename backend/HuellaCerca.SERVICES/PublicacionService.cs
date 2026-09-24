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
    public IReadOnlyList<CaracteristicaMascotaDto> Caracteristicas(int tipoMascota)
    {
        if (!Enum.IsDefined((TipoMascota)tipoMascota))
            throw new AppException(400, "Seleccioná un tipo de mascota válido.");
        var campos = new List<CaracteristicaMascotaDto>
        {
            new("tamano", "Tamaño", [new((int)TamanoMascota.Chico, "Chico"), new((int)TamanoMascota.Mediano, "Mediano"), new((int)TamanoMascota.Grande, "Grande")]),
            new("colorPredominante", "Color predominante", [new((int)ColorMascota.Negro, "Negro"), new((int)ColorMascota.Blanco, "Blanco"),
                new((int)ColorMascota.Marron, "Marrón"), new((int)ColorMascota.Gris, "Gris"), new((int)ColorMascota.Beige, "Beige"),
                new((int)ColorMascota.Naranja, "Naranja"), new((int)ColorMascota.MixtoOtro, "Mixto/Otro")])
        };
        if (tipoMascota is (int)TipoMascota.Perro or (int)TipoMascota.Gato)
        {
            campos.Insert(1, new("raza", "Raza", [new((int)ClasificacionRaza.DeRaza, "De raza"), new((int)ClasificacionRaza.Mestizo, "Mestizo")]));
            campos.Insert(2, new("pelaje", "Pelaje", [new((int)TipoPelaje.Corto, "Corto"), new((int)TipoPelaje.Medio, "Medio"), new((int)TipoPelaje.Largo, "Largo")]));
            campos.Add(new("colorOjos", "Color de ojos", [new((int)ColorOjosMascota.Oscuros, "Oscuros"), new((int)ColorOjosMascota.Claros, "Claros"), new((int)ColorOjosMascota.Diferentes, "Diferentes")]));
        }
        return campos;
    }

    public async Task<PublicacionDto> CrearAsync(Guid mascoteroId, CrearPublicacionRequest request, CancellationToken ct)
    {
        Validar(request);
        if (request.TipoMascota == (int)TipoMascota.Otro &&
            (request.Raza.HasValue || request.Pelaje.HasValue || request.ColorOjos.HasValue))
            throw new AppException(400, "Para otro tipo de mascota, indicá solo tamaño y color predominante; describí las demás características en la descripción.");
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
            Tamano = (TamanoMascota?)request.Tamano,
            Raza = (ClasificacionRaza?)request.Raza,
            Pelaje = (TipoPelaje?)request.Pelaje,
            ColorPredominante = (ColorMascota?)request.ColorPredominante,
            ColorOjos = (ColorOjosMascota?)request.ColorOjos,
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

    public async Task<PaginaDto<CoincidenciaPublicacionDto>> CoincidenciasAsync(Guid id, Guid mascoteroId, CoincidenciasQuery query, CancellationToken ct)
    {
        Validar(query);
        var origen = await ObtenerAsync(id, ct);
        if (origen.MascoteroId != mascoteroId)
            throw new AppException(403, "Solo el autor puede consultar las coincidencias de su aviso.");
        var requiereFecha = origen.TipoPublicacion is TipoPublicacionMascota.Perdida or TipoPublicacionMascota.Encontrada;
        if (origen.Estado != EstadoPublicacionMascota.Activa || (requiereFecha && origen.FechaSuceso is null))
            return new([], 0, query.Pagina, query.TamanoPagina);
        var (items, total) = await repository.CoincidenciasAsync(origen, query, ct);
        var resultados = items.Select(p => {
            var campos = new List<string>();
            if (origen.Tamano.HasValue && p.Tamano == origen.Tamano) campos.Add("Tamaño");
            if (origen.Raza.HasValue && p.Raza == origen.Raza) campos.Add("Raza");
            if (origen.Pelaje.HasValue && p.Pelaje == origen.Pelaje) campos.Add("Pelaje");
            if (origen.ColorPredominante.HasValue && p.ColorPredominante == origen.ColorPredominante) campos.Add("Color predominante");
            if (origen.ColorOjos.HasValue && p.ColorOjos == origen.ColorOjos) campos.Add("Color de ojos");
            return new CoincidenciaPublicacionDto(ToDto(p), campos);
        }).ToList();
        return new(resultados, total, query.Pagina, query.TamanoPagina);
    }

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
        p.Foto is null ? null : new FotoPublicacionDto(p.Foto.Id, $"api/publicaciones/{p.Id}/foto?v={p.Foto.Id}"),
        (int?)p.Tamano, (int?)p.Raza, (int?)p.Pelaje, (int?)p.ColorPredominante, (int?)p.ColorOjos);
}
