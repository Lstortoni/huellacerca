using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController, Authorize, Route("api/notificaciones")]
public sealed class NotificacionesController(INotificacionService service) : ControllerBase
{
    private Guid Autor => Guid.Parse(User.FindFirst("mascoteroId")!.Value);

    [HttpGet("{id:guid}/destino")]
    public async Task<IActionResult> Destino(Guid id, CancellationToken ct) =>
        Ok(new { publicacionId = await service.DestinoAsync(Autor, id, ct) });

    [HttpGet]
    public Task<PaginaDto<NotificacionDto>> Listar([FromQuery] NotificacionesQuery query, CancellationToken ct) =>
        service.ListarAsync(Autor, query, ct);

    [HttpGet("no-leidas/cantidad")]
    public async Task<IActionResult> Cantidad(CancellationToken ct) => Ok(new { cantidad = await service.ContarAsync(Autor, ct) });

    [HttpPatch("{id:guid}/leer")]
    public async Task<IActionResult> Leer(Guid id, CancellationToken ct)
    {
        await service.LeerAsync(Autor, id, ct);
        return NoContent();
    }

    [HttpPatch("leer-todas")]
    public async Task<IActionResult> LeerTodas(CancellationToken ct)
    {
        await service.LeerTodasAsync(Autor, ct);
        return NoContent();
    }
}
