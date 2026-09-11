using HuellaCerca.MODEL;
namespace HuellaCerca.INTERFACES.Repositories;

public interface IAuthRepository
{
    Task<Usuario?> PorEmailAsync(string email, CancellationToken ct);
    Task<Usuario?> PorIdAsync(Guid id, CancellationToken ct);
    Task<bool> LocalidadActivaAsync(Guid id, CancellationToken ct);
    void Agregar(Usuario usuario);
    void Agregar(RefreshToken token);
    Task<RefreshToken?> BuscarRefreshAsync(string hash, CancellationToken ct);
    Task RevocarSesionAsync(Guid sesionId, DateTime ahora, CancellationToken ct);
    Task GuardarAsync(CancellationToken ct);
}

