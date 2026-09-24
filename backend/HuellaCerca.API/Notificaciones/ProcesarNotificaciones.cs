using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.API.Notificaciones;

public sealed class ProcesarNotificaciones(IServiceScopeFactory scopes, ILogger<ProcesarNotificaciones> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopes.CreateScope();
                if (await scope.ServiceProvider.GetRequiredService<INotificacionService>().ProcesarLoteAsync(stoppingToken))
                    continue;
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { logger.LogError(ex, "No se pudo procesar el lote de notificaciones. Se reintentará."); }
            try { await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
        }
    }
}
