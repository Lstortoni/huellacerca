using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController]
[Route("api")]
public sealed class PrestadoresController(IRecomendacionService service) : ControllerBase
{
    [HttpGet("rubros")]
    public Task<IReadOnlyList<RubroDto>> Rubros(CancellationToken ct) => service.RubrosAsync(ct);
    [HttpGet("prestadores/similares")]
    public Task<IReadOnlyList<PrestadorDto>> Similares([FromQuery] SimilaresQuery query, CancellationToken ct) => service.SimilaresAsync(query, ct);
    [HttpGet("prestadores/{id:guid}")]
    public Task<PrestadorDto> Prestador(Guid id, CancellationToken ct) => service.PrestadorAsync(id, ct);
}

