namespace HuellaCerca.MODEL;

/// Aviso creado por un mascotero; no implica que sea el dueño del animal.
public sealed class PublicacionMascota
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MascoteroId { get; set; }
    public TipoPublicacionMascota TipoPublicacion { get; set; }
    public TipoMascota TipoMascota { get; set; }
    public TamanoMascota? Tamano { get; set; }
    public ClasificacionRaza? Raza { get; set; }
    public TipoPelaje? Pelaje { get; set; }
    public ColorMascota? ColorPredominante { get; set; }
    public ColorOjosMascota? ColorOjos { get; set; }
    public string? NombreMascota { get; set; }
    public string Descripcion { get; set; } = "";
    public DateOnly? FechaSuceso { get; set; }
    public Guid LocalidadId { get; set; }
    public string Zona { get; set; } = "";
    public string InformacionContacto { get; set; } = "";
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public EstadoPublicacionMascota Estado { get; set; } = EstadoPublicacionMascota.Activa;
    public Mascotero Mascotero { get; set; } = null!;
    public Localidad Localidad { get; set; } = null!;
    public FotoPublicacion? Foto { get; set; }
}
