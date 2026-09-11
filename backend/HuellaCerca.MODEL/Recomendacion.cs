namespace HuellaCerca.MODEL;

public sealed class Recomendacion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MascoteroId { get; set; }
    public Guid PrestadorServicioId { get; set; }
    public string Titulo { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime? FechaActualizacion { get; set; }
    public Mascotero Mascotero { get; set; } = null!;
    public PrestadorServicio PrestadorServicio { get; set; } = null!;
}

