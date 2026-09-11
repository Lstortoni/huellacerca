using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Auth;

public sealed class RegisterRequest
{
    [Required, StringLength(100)] public string Nombre { get; set; } = "";
    [Required, StringLength(100)] public string Apellido { get; set; } = "";
    [Required, EmailAddress, StringLength(254)] public string Email { get; set; } = "";
    [Required, StringLength(128, MinimumLength = 8)] public string Password { get; set; } = "";
    [Required, Compare(nameof(Password))] public string PasswordConfirm { get; set; } = "";
    [StringLength(40)] public string? Telefono { get; set; }
    public Guid LocalidadId { get; set; }
}
public sealed class LoginRequest
{
    [Required, EmailAddress, StringLength(254)] public string Email { get; set; } = "";
    [Required, StringLength(128)] public string Password { get; set; } = "";
}
public sealed class RefreshRequest
{
    [Required, StringLength(256, MinimumLength = 32)] public string RefreshToken { get; set; } = "";
}
public sealed record MascoteroDto(Guid Id, string Nombre, string Apellido, string? Telefono, Guid LocalidadId);
public sealed record UsuarioActualDto(Guid Id, string Email, bool EmailConfirmado, MascoteroDto Mascotero);
public sealed record AuthResponse(string AccessToken, DateTime ExpiresAtUtc, string RefreshToken,
    DateTime RefreshExpiresAtUtc, UsuarioActualDto Usuario);

