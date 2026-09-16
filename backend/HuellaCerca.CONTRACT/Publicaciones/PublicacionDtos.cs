using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Publicaciones;

public sealed class CrearPublicacionRequest
{
    [Range(1, 2)] public int TipoPublicacion { get; set; }
    [Range(1, 3)] public int TipoMascota { get; set; }
    [StringLength(100)] public string? NombreMascota { get; set; }
    [Required, StringLength(3000, MinimumLength = 10)] public string Descripcion { get; set; } = "";
    public DateOnly FechaSuceso { get; set; }
    public Guid LocalidadId { get; set; }
    [Required, StringLength(250)] public string Zona { get; set; } = "";
    [Required, StringLength(500)] public string InformacionContacto { get; set; } = "";
}

public sealed class PublicacionesQuery : IValidatableObject
{
    [Range(1, 2)] public int? TipoPublicacion { get; set; }
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
        if (FechaDesde.HasValue && FechaHasta.HasValue && FechaDesde > FechaHasta)
            yield return new ValidationResult("La fecha desde no puede superar la fecha hasta.", [nameof(FechaDesde), nameof(FechaHasta)]);
    }
}

public sealed record PublicacionDto(Guid Id, Guid MascoteroId, string Autor, int TipoPublicacion,
    int TipoMascota, string? NombreMascota, string Descripcion, DateOnly FechaSuceso,
    Guid LocalidadId, string Localidad, Guid ProvinciaId, string Provincia, string Zona,
    string InformacionContacto, DateTime FechaCreacion, int Estado, IReadOnlyList<FotoPublicacionDto> Fotografias);

// La carga y entrega de archivos se incorporará en el siguiente bloque.
public sealed record FotoPublicacionDto(Guid Id, int Orden);
