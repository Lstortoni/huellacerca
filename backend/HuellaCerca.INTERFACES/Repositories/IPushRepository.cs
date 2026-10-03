using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.INTERFACES.Repositories;

public interface IPushRepository
{
    Task RegistrarAsync(Guid instalacion, Guid autor, Guid sesion, RegistrarDispositivoRequest request, CancellationToken ct);
    Task DesactivarAsync(Guid instalacion, Guid autor, Guid sesion, CancellationToken ct);
    Task<TrabajoPush?> ReservarAsync(CancellationToken ct);
    Task CompletarAsync(TrabajoPush trabajo, ResultadoPush resultado, CancellationToken ct);
}
