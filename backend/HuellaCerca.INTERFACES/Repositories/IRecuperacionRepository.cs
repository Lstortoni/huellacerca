namespace HuellaCerca.INTERFACES.Repositories;

public interface IRecuperacionRepository
{
    Task<bool> PrepararAsync(string email, Guid codigoId, string codigoHash, DateTime ahora, CancellationToken ct);
    Task<bool> VerificarAsync(string email, Func<Guid, string, bool> verificarHash,
        string permisoHash, DateTime ahora, CancellationToken ct);
    Task<bool> ConsumirAsync(string permisoHash, string passwordHash, DateTime ahora, CancellationToken ct);
}
