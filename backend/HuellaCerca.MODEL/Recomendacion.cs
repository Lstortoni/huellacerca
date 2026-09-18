namespace HuellaCerca.MODEL;

public sealed class Recomendacion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MascoteroId { get; set; }
    public Guid PrestadorServicioId { get; set; }
    public ICollection<RecomendacionAspecto> Aspectos { get; set; } = new List<RecomendacionAspecto>();
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime? FechaActualizacion { get; set; }
    public Mascotero Mascotero { get; set; } = null!;
    public PrestadorServicio PrestadorServicio { get; set; } = null!;
}
