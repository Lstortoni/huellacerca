using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Ubicacion;

/// Sin ProvinciaId busca en todo el país; en ese caso la búsqueda debe tener al menos 2 letras.
public sealed class LocalidadesQuery
{
    public Guid? ProvinciaId { get; set; }
    [StringLength(150)]
    public string? Busqueda { get; set; }
    [Range(1, 1000000)]
    public int Pagina { get; set; } = 1;
    [Range(1, 100)]
    public int TamanoPagina { get; set; } = 20;
}

