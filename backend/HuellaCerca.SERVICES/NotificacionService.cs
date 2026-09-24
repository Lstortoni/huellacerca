using System.ComponentModel.DataAnnotations;
using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.SERVICES;

public sealed class NotificacionService(INotificacionRepository repository) : INotificacionService
{
    public Task<PaginaDto<NotificacionDto>> ListarAsync(Guid autor, NotificacionesQuery query, CancellationToken ct)
    {
        var errors = new List<ValidationResult>();
        if (!Validator.TryValidateObject(query, new ValidationContext(query), errors, true))
            throw new AppException(400, errors[0].ErrorMessage ?? "Paginación inválida.");
        return repository.ListarAsync(autor, query, ct);
    }
    public Task<int> ContarAsync(Guid autor, CancellationToken ct) => repository.ContarAsync(autor, ct);
    public async Task LeerAsync(Guid autor, Guid id, CancellationToken ct)
    {
        if (!await repository.LeerAsync(autor, id, ct)) throw new AppException(404, "Notificación no encontrada.");
    }
    public Task LeerTodasAsync(Guid autor, CancellationToken ct) => repository.LeerTodasAsync(autor, ct);
    public Task<bool> ProcesarLoteAsync(CancellationToken ct) => repository.ProcesarLoteAsync(ct);
}
