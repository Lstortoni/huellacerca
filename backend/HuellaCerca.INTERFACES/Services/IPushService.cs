using HuellaCerca.CONTRACT.Notificaciones;

namespace HuellaCerca.INTERFACES.Services;

public interface IPushService
{
    Task RegistrarAsync(Guid instalacion, Guid autor, Guid sesion, RegistrarDispositivoRequest request, CancellationToken ct);
    Task DesactivarAsync(Guid instalacion, Guid autor, Guid sesion, CancellationToken ct);
    Task<bool> ProcesarAsync(CancellationToken ct);
}

public enum ResultadoPush { Enviado, TokenInvalido, Reintentar }

public interface IEmisorPush
{
    bool Habilitado { get; }
    Task<ResultadoPush> EnviarAsync(TrabajoPush trabajo, CancellationToken ct);
}

public sealed record TrabajoPush(Guid Id, Guid Reserva, Guid DispositivoId, Guid VersionDispositivo,
    string Token, Guid MascoteroId, Guid NotificacionId, Guid PublicacionId,
    string Titulo, string Mensaje, int Intentos, DateTime FechaCreacion);
