using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.CONTRACT.Ubicacion;

namespace HuellaCerca.INTERFACES.Repositories;

public interface INotificacionRepository
{
    Task<Guid?> DestinoAsync(Guid autor, Guid id, CancellationToken ct);
    Task<PaginaDto<NotificacionDto>> ListarAsync(Guid autor, NotificacionesQuery query, CancellationToken ct);
    Task<int> ContarAsync(Guid autor, CancellationToken ct);
    Task<bool> LeerAsync(Guid autor, Guid id, CancellationToken ct);
    Task LeerTodasAsync(Guid autor, CancellationToken ct);
    Task<bool> ProcesarLoteAsync(CancellationToken ct);
}
