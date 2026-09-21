using HuellaCerca.MODEL;
namespace HuellaCerca.INTERFACES.Repositories;

public interface IFotoRepository
{
    Task<PublicacionMascota?> ObtenerAsync(Guid id, CancellationToken ct);
    Task PrepararAsync(string key, CancellationToken ct);
    Task ConfirmarAsync(Guid id, Guid? fotoAnterior, FotoPublicacion? foto, CancellationToken ct);
    Task<IReadOnlyList<string>> PendientesAsync(CancellationToken ct);
    Task CompletarLimpiezaAsync(string key, CancellationToken ct);
}
