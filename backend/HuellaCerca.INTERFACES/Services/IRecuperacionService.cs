using HuellaCerca.CONTRACT.Auth;

namespace HuellaCerca.INTERFACES.Services;

public interface IRecuperacionService
{
    Task EnviarCodigoAsync(string email, CancellationToken ct);
    Task<PermisoRecuperacionDto> VerificarAsync(VerifyResetCodeRequest request, CancellationToken ct);
    Task RestablecerAsync(ResetPasswordRequest request, CancellationToken ct);
}
