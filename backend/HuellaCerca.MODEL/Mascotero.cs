namespace HuellaCerca.MODEL;

public sealed class Mascotero
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Nombre { get; set; } = "";
    public string Apellido { get; set; } = "";
    public string? Telefono { get; set; }
    public Guid LocalidadId { get; set; }
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public Localidad Localidad { get; set; } = null!;
    public Usuario Usuario { get; set; } = null!;
    public ICollection<Recomendacion> Recomendaciones { get; set; } = new List<Recomendacion>();
    public ICollection<PublicacionMascota> PublicacionesMascotas { get; set; } = new List<PublicacionMascota>();
}
