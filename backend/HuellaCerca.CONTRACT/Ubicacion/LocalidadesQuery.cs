using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Ubicacion;

public sealed class LocalidadesQuery
{
    [Required]
    public Guid? ProvinciaId { get; set; }
    [StringLength(150)]
    public string? Busqueda { get; set; }
    [Range(1, 1000000)]
    public int Pagina { get; set; } = 1;
    [Range(1, 100)]
    public int TamanoPagina { get; set; } = 20;
}

