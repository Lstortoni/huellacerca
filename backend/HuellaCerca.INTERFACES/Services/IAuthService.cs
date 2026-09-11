using HuellaCerca.CONTRACT.Auth;
namespace HuellaCerca.INTERFACES.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct);
    Task<AuthResponse> RefreshAsync(string token, CancellationToken ct);
    Task LogoutAsync(string token, CancellationToken ct);
    Task<UsuarioActualDto> MeAsync(Guid usuarioId, CancellationToken ct);
}

