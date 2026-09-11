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
    [HttpGet, AllowAnonymous]
    public Task<PaginaDto<RecomendacionDto>> Buscar([FromQuery] RecomendacionesQuery query, CancellationToken ct) => service.BuscarAsync(query, ct);
    [HttpGet("{id:guid}"), AllowAnonymous]
    public Task<RecomendacionDto> Detalle(Guid id, CancellationToken ct) => service.PorIdAsync(id, ct);
    [HttpPost, Authorize]
    public async Task<ActionResult<RecomendacionDto>> Crear(CrearRecomendacionRequest request, CancellationToken ct)
    {
        var result = await service.CrearAsync(MascoteroId, request, ct);
        return CreatedAtAction(nameof(Detalle), new { id = result.Id }, result);
    }
    [HttpPut("{id:guid}"), Authorize]
    public Task<RecomendacionDto> Editar(Guid id, EditarRecomendacionRequest request, CancellationToken ct) => service.EditarAsync(id, MascoteroId, request, ct);
    [HttpDelete("{id:guid}"), Authorize]
    public async Task<IActionResult> Eliminar(Guid id, CancellationToken ct)
    {
        await service.EliminarAsync(id, MascoteroId, ct);
        return NoContent();
    }
    private Guid MascoteroId => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
}

