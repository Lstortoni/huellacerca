namespace HuellaCerca.MODEL;

/// Una solicitud vigente por usuario; se conservan los contadores de envío.
public sealed class RecuperacionPassword
{
    public Guid UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;
    public Guid CodigoId { get; set; }
    public string CodigoHash { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
    public DateTime FechaExpiracion { get; set; }
    public int IntentosFallidos { get; set; }
    public bool CodigoVerificado { get; set; }
    public string? PermisoHash { get; set; }
    public DateTime? PermisoExpira { get; set; }
    public DateTime? FechaUso { get; set; }
    public DateTime VentanaEnvios { get; set; }
    public int Envios { get; set; }
}
