using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController]
[Route("api/recomendaciones")]
public sealed class RecomendacionesController(IRecomendacionService service) : ControllerBase
{
    [HttpGet("mias"), Authorize]
    public Task<PaginaDto<RecomendacionDto>> Mias([FromQuery] RecomendacionesQuery query, CancellationToken ct) => service.MiasAsync(MascoteroId, query, ct);
    [HttpGet("{id:guid}"), Authorize]
    public Task<RecomendacionDto> Detalle(Guid id, CancellationToken ct) => service.PorIdAsync(id, MascoteroId, ct);
    [HttpPost, Authorize]
    public async Task<ActionResult<RecomendacionDto>> Crear(CrearRecomendacionRequest request, CancellationToken ct)
    {
        var result = await service.CrearAsync(MascoteroId, request, ct);
        return result.Creada ? CreatedAtAction(nameof(Detalle), new { id = result.Item.Id }, result.Item) : Ok(result.Item);
    }
    [HttpPut("{id:guid}/aspectos"), Authorize]
    public Task<RecomendacionDto> Editar(Guid id, EditarRecomendacionRequest request, CancellationToken ct) => service.EditarAsync(id, MascoteroId, request, ct);
    [HttpDelete("{id:guid}"), Authorize]
    public async Task<IActionResult> Eliminar(Guid id, CancellationToken ct)
    {
        await service.EliminarAsync(id, MascoteroId, ct);
        return NoContent();
    }
    private Guid MascoteroId => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
}
