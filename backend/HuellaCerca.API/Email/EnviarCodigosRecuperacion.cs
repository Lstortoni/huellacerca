using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.API.Email;

public sealed class EnviarCodigosRecuperacion(ColaRecuperacion cola, IServiceScopeFactory scopes,
    ILogger<EnviarCodigosRecuperacion> logger) : BackgroundService
{
    protected override Task ExecuteAsync(CancellationToken stoppingToken) =>
        Task.WhenAll(ProcesarAsync(stoppingToken), ProcesarAsync(stoppingToken));

    private async Task ProcesarAsync(CancellationToken ct)
    {
        try
        {
            await foreach (var item in cola.LeerAsync(ct))
            {
                if (item.Fecha.AddMinutes(2) < DateTime.UtcNow) continue;
                try
                {
                    using var scope = scopes.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<IRecuperacionService>().EnviarCodigoAsync(item.Email, ct);
                }
                catch (OperationCanceledException) when (ct.IsCancellationRequested) { return; }
                catch (Exception)
                {
                    // No incluir excepción, destinatario ni contenido del correo.
                    logger.LogWarning("No se completó una solicitud de correo de recuperación. El usuario puede volver a solicitarla.");
                }
            }
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested) { }
    }
}
