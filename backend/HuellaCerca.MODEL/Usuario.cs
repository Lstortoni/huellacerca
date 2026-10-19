namespace HuellaCerca.MODEL;

public sealed class Usuario
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MascoteroId { get; set; }
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public Guid VersionSeguridad { get; set; }
    public bool EmailConfirmado { get; set; }
    public bool Activo { get; set; } = true;
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime? UltimoAcceso { get; set; }
    public Mascotero Mascotero { get; set; } = null!;
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}

