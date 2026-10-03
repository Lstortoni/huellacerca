using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Notificaciones;

public sealed class RegistrarDispositivoRequest
{
    [Required, StringLength(2048, MinimumLength = 20)]
    public string Token { get; init; } = "";
    [Required, RegularExpression("^(android|ios)$")]
    public string Plataforma { get; init; } = "android";
}
