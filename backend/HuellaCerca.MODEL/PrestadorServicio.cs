namespace HuellaCerca.MODEL;

public sealed class PrestadorServicio
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Nombre { get; set; } = "";
    public string NombreBusqueda { get; set; } = "";
    public Guid RubroId { get; set; }
    public Guid LocalidadId { get; set; }
    public Guid MascoteroCreadorId { get; set; }
    public string? Direccion { get; set; }
    public string? Telefono { get; set; }
    public string? Enlace { get; set; }
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public bool Activo { get; set; } = true;
    public Rubro Rubro { get; set; } = null!;
    public Localidad Localidad { get; set; } = null!;
    public Mascotero MascoteroCreador { get; set; } = null!;
    public ICollection<Recomendacion> Recomendaciones { get; set; } = new List<Recomendacion>();
}

