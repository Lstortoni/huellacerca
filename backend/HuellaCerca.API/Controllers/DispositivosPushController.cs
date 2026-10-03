using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController, Authorize, Route("api/dispositivos-push")]
public sealed class DispositivosPushController(IPushService service) : ControllerBase
{
    private Guid Autor => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
    private Guid Sesion => Guid.TryParse(User.FindFirst("sid")?.Value, out var id) ? id : Guid.Empty;

    [HttpPut("{instalacion:guid}")]
    public async Task<IActionResult> Registrar(Guid instalacion, RegistrarDispositivoRequest request, CancellationToken ct)
    {
        await service.RegistrarAsync(instalacion, Autor, Sesion, request, ct);
        return NoContent();
    }

    [HttpDelete("{instalacion:guid}")]
    public async Task<IActionResult> Desactivar(Guid instalacion, CancellationToken ct)
    {
        await service.DesactivarAsync(instalacion, Autor, Sesion, ct);
        return NoContent();
    }
}
