using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController]
[Route("api/publicaciones")]
public sealed class PublicacionesController(IPublicacionService service) : ControllerBase
{
    [HttpGet, AllowAnonymous]
    public Task<PaginaDto<PublicacionDto>> Buscar([FromQuery] PublicacionesQuery query, CancellationToken ct) =>
        service.BuscarAsync(query, ct);

    [HttpGet("{id:guid}"), AllowAnonymous]
    public Task<PublicacionDto> Detalle(Guid id, CancellationToken ct) => service.PorIdAsync(id, ct);

    [HttpPost, Authorize]
    public async Task<ActionResult<PublicacionDto>> Crear(CrearPublicacionRequest request, CancellationToken ct)
    {
        var result = await service.CrearAsync(MascoteroId, request, ct);
        return CreatedAtAction(nameof(Detalle), new { id = result.Id }, result);
    }

    [HttpPatch("{id:guid}/resolver"), Authorize]
    public Task<PublicacionDto> Resolver(Guid id, CancellationToken ct) => service.ResolverAsync(id, MascoteroId, ct);

    private Guid MascoteroId => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
}
