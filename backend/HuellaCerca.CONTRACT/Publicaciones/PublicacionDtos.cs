using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Publicaciones;

public class DatosPublicacionRequest
{
    [Range(1, 3)] public int TipoMascota { get; set; }
    [Range(1, 3)] public int? Tamano { get; set; }
    [Range(1, 2)] public int? Raza { get; set; }
    [Range(1, 3)] public int? Pelaje { get; set; }
    [Range(1, 7)] public int? ColorPredominante { get; set; }
    [Range(1, 3)] public int? ColorOjos { get; set; }
    [StringLength(100)] public string? NombreMascota { get; set; }
    [Required, StringLength(3000, MinimumLength = 10)] public string Descripcion { get; set; } = "";
    public DateOnly? FechaSuceso { get; set; }
    public Guid LocalidadId { get; set; }
    [StringLength(250)] public string? Zona { get; set; }
    [Required, StringLength(500)] public string InformacionContacto { get; set; } = "";
}

public sealed class CrearPublicacionRequest : DatosPublicacionRequest
{
    [Range(1, 4)] public int TipoPublicacion { get; set; }
}

[System.Text.Json.Serialization.JsonUnmappedMemberHandling(System.Text.Json.Serialization.JsonUnmappedMemberHandling.Disallow)]
public sealed class EditarPublicacionRequest : DatosPublicacionRequest
{
    [Required] public Guid? Version { get; set; }
}

public sealed class PublicacionesQuery : IValidatableObject
{
    [Range(1, 3)] public int? Tamano { get; set; }
    [Range(1, 2)] public int? Raza { get; set; }
    [Range(1, 3)] public int? Pelaje { get; set; }
    [Range(1, 7)] public int? ColorPredominante { get; set; }
    [Range(1, 3)] public int? ColorOjos { get; set; }
    [Range(1, 4)] public int? TipoPublicacion { get; set; }
    [Range(1, 3)] public int? TipoMascota { get; set; }
    [Range(1, 2)] public int? Estado { get; set; }
    public Guid? ProvinciaId { get; set; }
    public Guid? LocalidadId { get; set; }
    public Guid? MascoteroId { get; set; }
    [StringLength(250)] public string? Zona { get; set; }
    public DateOnly? FechaDesde { get; set; }
    public DateOnly? FechaHasta { get; set; }
    [Range(1, 1000000)] public int Pagina { get; set; } = 1;
    [Range(1, 100)] public int TamanoPagina { get; set; } = 20;

    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (TipoMascota == 3 && (Raza.HasValue || Pelaje.HasValue || ColorOjos.HasValue))
            yield return new ValidationResult("Para otro tipo de mascota, filtrá solo por tamaño y color predominante.", [nameof(TipoMascota)]);
        if (FechaDesde.HasValue && FechaHasta.HasValue && FechaDesde > FechaHasta)
            yield return new ValidationResult("La fecha desde no puede superar la fecha hasta.", [nameof(FechaDesde), nameof(FechaHasta)]);
    }
}

public sealed record PublicacionDto(Guid Id, Guid MascoteroId, string Autor, int TipoPublicacion,
    int TipoMascota, string? NombreMascota, string Descripcion, DateOnly? FechaSuceso,
    Guid LocalidadId, string Localidad, Guid ProvinciaId, string Provincia, string Zona,
    string InformacionContacto, DateTime FechaCreacion, int Estado, FotoPublicacionDto? Foto,
    int? Tamano, int? Raza, int? Pelaje, int? ColorPredominante, int? ColorOjos,
    DateTime? FechaActualizacion = null, Guid Version = default);

public sealed record OpcionCaracteristicaDto(int Id, string Nombre);
public sealed class CoincidenciasQuery
{
    [Range(1, 1000000)] public int Pagina { get; set; } = 1;
    [Range(1, 20)] public int TamanoPagina { get; set; } = 10;
}

public sealed record CoincidenciaPublicacionDto(PublicacionDto Publicacion, IReadOnlyList<string> CoincideEn);
public sealed record CaracteristicaMascotaDto(string Campo, string Nombre, IReadOnlyList<OpcionCaracteristicaDto> Opciones);

// URL relativa a la API; nunca expone credenciales ni el contenido binario en JSON.
public sealed record FotoPublicacionDto(Guid Id, string Url)
{
    /// Ruta versionada: cambia al reemplazar la foto, así la app no usa una copia vieja.
    public static string Ruta(Guid publicacionId, Guid fotoId) => $"api/publicaciones/{publicacionId}/foto?v={fotoId}";
}
