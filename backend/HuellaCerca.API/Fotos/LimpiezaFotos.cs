using HuellaCerca.INTERFACES.Services;
namespace HuellaCerca.API.Fotos;

public sealed class LimpiezaFotos(IServiceScopeFactory scopes, ILogger<LimpiezaFotos> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopes.CreateScope();
                await scope.ServiceProvider.GetRequiredService<IFotoService>().LimpiarAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception) { logger.LogWarning("No se pudo completar la limpieza de fotos; se reintentará."); }
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }
}
