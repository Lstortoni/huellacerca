using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Auth;

public sealed class ForgotPasswordRequest
{
    [Required, EmailAddress, StringLength(254)] public string Email { get; set; } = "";
}
public sealed class VerifyResetCodeRequest
{
    [Required, EmailAddress, StringLength(254)] public string Email { get; set; } = "";
    [Required, RegularExpression("^[0-9]{6}$")] public string Codigo { get; set; } = "";
}
public sealed class ResetPasswordRequest
{
    [Required, StringLength(128, MinimumLength = 64)] public string ResetToken { get; set; } = "";
    [Required, StringLength(128, MinimumLength = 8)] public string Password { get; set; } = "";
    [Required, Compare(nameof(Password))] public string PasswordConfirm { get; set; } = "";
}
public sealed record PermisoRecuperacionDto(string ResetToken, DateTime ExpiresAtUtc);
