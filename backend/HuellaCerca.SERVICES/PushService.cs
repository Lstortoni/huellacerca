using System.ComponentModel.DataAnnotations;
using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.SERVICES;

public sealed class PushService(IPushRepository repository, IEmisorPush emisor) : IPushService
{
    public Task RegistrarAsync(Guid instalacion, Guid autor, Guid sesion, RegistrarDispositivoRequest request, CancellationToken ct)
    {
        if (instalacion == Guid.Empty || sesion == Guid.Empty || string.IsNullOrWhiteSpace(request.Token)
            || request.Token.Any(c => c > 127 || char.IsWhiteSpace(c))
            || !Validator.TryValidateObject(request, new ValidationContext(request), [], true))
            throw new AppException(400, "Dispositivo push inválido.");
        return repository.RegistrarAsync(instalacion, autor, sesion, request, ct);
    }
    public Task DesactivarAsync(Guid instalacion, Guid autor, Guid sesion, CancellationToken ct) =>
        repository.DesactivarAsync(instalacion, autor, sesion, ct);

    public async Task<bool> ProcesarAsync(CancellationToken ct)
    {
        if (!emisor.Habilitado) return false;
        var trabajo = await repository.ReservarAsync(ct);
        if (trabajo is null) return false;
        // El envío de red queda fuera de la transacción que generó la notificación.
        ResultadoPush resultado;
        try { resultado = await emisor.EnviarAsync(trabajo, ct); }
        catch (OperationCanceledException) when (ct.IsCancellationRequested) { throw; }
        catch { resultado = ResultadoPush.Reintentar; }
        await repository.CompletarAsync(trabajo, resultado, ct);
        return true;
    }
}
