namespace HuellaCerca.MODEL;

public sealed class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UsuarioId { get; set; }
    public Guid SesionId { get; set; }
    public Guid VersionSeguridad { get; set; }
    public string TokenHash { get; set; } = "";
    public DateTime FechaCreacion { get; set; }
    public DateTime FechaExpiracion { get; set; }
    public DateTime? FechaRevocacion { get; set; }
    public Usuario Usuario { get; set; } = null!;
}

