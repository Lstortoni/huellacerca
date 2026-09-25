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
        await ValidarDatosAsync(request, request.TipoPublicacion, ct);
        var publicacion = new PublicacionMascota { MascoteroId = mascoteroId,
            TipoPublicacion = (TipoPublicacionMascota)request.TipoPublicacion };
        Aplicar(publicacion, request);
        repository.Agregar(publicacion);
        await repository.GuardarAsync(ct);
        return await PorIdAsync(publicacion.Id, ct);
    }

    public async Task<PublicacionDto> EditarAsync(Guid id, Guid mascoteroId, EditarPublicacionRequest request, CancellationToken ct)
    {
        var p = await ObtenerAsync(id, ct);
        if (p.MascoteroId != mascoteroId) throw new AppException(403, "Solo el autor puede editar esta publicación.");
        await ValidarDatosAsync(request, (int)p.TipoPublicacion, ct);
        if (request.Version != p.Version)
            throw new AppException(409, "La publicación cambió. Volvé a cargarla antes de guardar.");
        var fecha = (int)p.TipoPublicacion <= 2 ? request.FechaSuceso : null;
        var revisar = p.Estado == EstadoPublicacionMascota.Activa &&
            ((int)p.TipoMascota != request.TipoMascota || p.LocalidadId != request.LocalidadId
            || p.FechaSuceso != fecha || (int?)p.Tamano != request.Tamano || (int?)p.Raza != request.Raza
            || (int?)p.Pelaje != request.Pelaje || (int?)p.ColorPredominante != request.ColorPredominante
            || (int?)p.ColorOjos != request.ColorOjos);
        Aplicar(p, request);
        p.FechaActualizacion = DateTime.UtcNow;
        await repository.GuardarEdicionAsync(p, revisar, ct);
        return await PorIdAsync(id, ct);
    }

    private async Task ValidarDatosAsync(DatosPublicacionRequest request, int tipoPublicacion, CancellationToken ct)
    {
        Validar(request);
        if (request.TipoMascota == (int)TipoMascota.Otro &&
            (request.Raza.HasValue || request.Pelaje.HasValue || request.ColorOjos.HasValue))
            throw new AppException(400, "Para otro tipo de mascota, indicá solo tamaño y color predominante; describí las demás características en la descripción.");
        if (request.Descripcion.Trim().Length < 10)
            throw new AppException(400, "Describí la mascota y lo sucedido en al menos 10 caracteres.");
        // FechaSuceso no contiene hora; se compara con el día actual en Argentina.
        var hoy = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "America/Argentina/Buenos_Aires"));
        var requiereFecha = tipoPublicacion is 1 or 2;
        if (requiereFecha && (request.FechaSuceso is null || request.FechaSuceso == DateOnly.MinValue || request.FechaSuceso > hoy))
            throw new AppException(400, "Indicá una fecha del suceso válida, que no sea futura.");
        if (tipoPublicacion != 4 && string.IsNullOrWhiteSpace(request.Zona))
            throw new AppException(400, "Indicá la zona aproximada.");
        if (!await ubicaciones.LocalidadActivaAsync(request.LocalidadId, ct))
            throw new AppException(400, "Seleccioná una localidad activa.");

    }

    private static void Aplicar(PublicacionMascota p, DatosPublicacionRequest request)
    {
        p.TipoMascota = (TipoMascota)request.TipoMascota;
        p.Tamano = (TamanoMascota?)request.Tamano;
        p.Raza = (ClasificacionRaza?)request.Raza;
        p.Pelaje = (TipoPelaje?)request.Pelaje;
        p.ColorPredominante = (ColorMascota?)request.ColorPredominante;
        p.ColorOjos = (ColorOjosMascota?)request.ColorOjos;
        p.NombreMascota = (int)p.TipoPublicacion == 4 || string.IsNullOrWhiteSpace(request.NombreMascota) ? null : request.NombreMascota.Trim();
        p.Descripcion = request.Descripcion.Trim();
        p.FechaSuceso = (int)p.TipoPublicacion <= 2 ? request.FechaSuceso : null;
        p.LocalidadId = request.LocalidadId;
        p.Zona = request.Zona?.Trim() ?? "";
        p.InformacionContacto = request.InformacionContacto.Trim();
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

    public async Task<PublicacionDto> ReabrirAsync(Guid id, Guid mascoteroId, CancellationToken ct)
    {
        var p = await ObtenerAsync(id, ct);
        if (p.MascoteroId != mascoteroId)
            throw new AppException(403, "Solo el autor puede reabrir esta publicación.");
        // Repetir la petición sobre un aviso activo no modifica versión ni vuelve a encolar.
        if (p.Estado == EstadoPublicacionMascota.Activa) return ToDto(p);
        p.Estado = EstadoPublicacionMascota.Activa;
        p.FechaActualizacion = DateTime.UtcNow;
        await repository.GuardarEdicionAsync(p, revisarCoincidencias: true, ct);
        return await PorIdAsync(id, ct);
    }

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
        p.Foto is null ? null : new FotoPublicacionDto(p.Foto.Id, FotoPublicacionDto.Ruta(p.Id, p.Foto.Id)),
        (int?)p.Tamano, (int?)p.Raza, (int?)p.Pelaje, (int?)p.ColorPredominante, (int?)p.ColorOjos,
        p.FechaActualizacion, p.Version);
}
