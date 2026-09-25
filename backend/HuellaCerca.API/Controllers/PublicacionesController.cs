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
    [HttpGet("caracteristicas"), AllowAnonymous]
    public IReadOnlyList<CaracteristicaMascotaDto> Caracteristicas([FromQuery] int tipoMascota = 1) =>
        service.Caracteristicas(tipoMascota);

    [HttpGet, AllowAnonymous]
    public Task<PaginaDto<PublicacionDto>> Buscar([FromQuery] PublicacionesQuery query, CancellationToken ct) =>
        service.BuscarAsync(query, ct);

    [HttpGet("{id:guid}"), AllowAnonymous]
    public Task<PublicacionDto> Detalle(Guid id, CancellationToken ct) => service.PorIdAsync(id, ct);

    [HttpGet("{id:guid}/coincidencias"), Authorize]
    public Task<PaginaDto<CoincidenciaPublicacionDto>> Coincidencias(Guid id, [FromQuery] CoincidenciasQuery query, CancellationToken ct) =>
        service.CoincidenciasAsync(id, MascoteroId, query, ct);

    [HttpPost, Authorize]
    public async Task<ActionResult<PublicacionDto>> Crear(CrearPublicacionRequest request, CancellationToken ct)
    {
        var result = await service.CrearAsync(MascoteroId, request, ct);
        return CreatedAtAction(nameof(Detalle), new { id = result.Id }, result);
    }

    [HttpPatch("{id:guid}/resolver"), Authorize]
    public Task<PublicacionDto> Resolver(Guid id, CancellationToken ct) => service.ResolverAsync(id, MascoteroId, ct);

    private Guid MascoteroId => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
    [HttpPatch("{id:guid}/reabrir"), Authorize]
    public Task<PublicacionDto> Reabrir(Guid id, CancellationToken ct) => service.ReabrirAsync(id, MascoteroId, ct);
    [HttpPut("{id:guid}"), Authorize]
    public Task<PublicacionDto> Editar(Guid id, EditarPublicacionRequest request, CancellationToken ct) =>
        service.EditarAsync(id, MascoteroId, request, ct);
}
