using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Recomendaciones;

public sealed class PrestadorRequest
{
    [Required, StringLength(150)] public string Nombre { get; set; } = "";
    public Guid RubroId { get; set; }
    public Guid LocalidadId { get; set; }
    [StringLength(250)] public string? Direccion { get; set; }
    [StringLength(40)] public string? Telefono { get; set; }
    [StringLength(500)] public string? Enlace { get; set; }
}
public sealed class CrearRecomendacionRequest : IValidatableObject
{
    public Guid? PrestadorServicioId { get; set; }
    public PrestadorRequest? NuevoPrestador { get; set; }
    [Required, StringLength(150)] public string Titulo { get; set; } = "";
    [Required, StringLength(3000, MinimumLength = 10)] public string Descripcion { get; set; } = "";
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (PrestadorServicioId.HasValue == (NuevoPrestador is not null))
            yield return new ValidationResult("Elegí un prestador existente o cargá uno nuevo, no ambos.", [nameof(PrestadorServicioId), nameof(NuevoPrestador)]);
    }
}
public sealed class EditarRecomendacionRequest
{
    [Required, StringLength(150)] public string Titulo { get; set; } = "";
    [Required, StringLength(3000, MinimumLength = 10)] public string Descripcion { get; set; } = "";
}
public sealed class RecomendacionesQuery
{
    [StringLength(150)] public string? Busqueda { get; set; }
    public Guid? RubroId { get; set; }
    public Guid? ProvinciaId { get; set; }
    public Guid? LocalidadId { get; set; }
    public Guid? MascoteroId { get; set; }
    [Range(1, 1000000)] public int Pagina { get; set; } = 1;
    [Range(1, 100)] public int TamanoPagina { get; set; } = 20;
}
public sealed class SimilaresQuery
{
    [Required, StringLength(150, MinimumLength = 2)] public string Nombre { get; set; } = "";
    public Guid RubroId { get; set; }
    public Guid LocalidadId { get; set; }
    [Range(1, 20)] public int Limite { get; set; } = 10;
}
public sealed record RubroDto(Guid Id, string Nombre);
public sealed record PrestadorDto(Guid Id, string Nombre, Guid RubroId, string Rubro, Guid LocalidadId,
    string Localidad, string? Direccion, string? Telefono, string? Enlace);
public sealed record RecomendacionDto(Guid Id, Guid MascoteroId, string Autor, string Titulo,
    string Descripcion, DateTime FechaCreacion, DateTime? FechaActualizacion, PrestadorDto Prestador);

