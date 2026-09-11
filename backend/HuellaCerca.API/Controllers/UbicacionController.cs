using System.ComponentModel.DataAnnotations;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Mvc;

namespace HuellaCerca.API.Controllers;

[ApiController]
[Route("api")]
public sealed class UbicacionController(IUbicacionService service) : ControllerBase
{
    [HttpGet("paises")]
    public Task<IReadOnlyList<PaisDto>> Paises(CancellationToken ct) => service.GetPaisesAsync(ct);

    [HttpGet("provincias")]
    public Task<IReadOnlyList<ProvinciaDto>> Provincias(
        [FromQuery, RegularExpression("^[a-zA-Z]{2}$")] string paisCodigo = "AR", CancellationToken ct = default) =>
        service.GetProvinciasAsync(paisCodigo, ct);

    [HttpGet("localidades")]
    [ProducesResponseType(typeof(PaginaDto<LocalidadDto>), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
    public async Task<ActionResult<PaginaDto<LocalidadDto>>> Localidades([FromQuery] LocalidadesQuery query, CancellationToken ct)
    {
        if (query.ProvinciaId == Guid.Empty)
        {
            ModelState.AddModelError(nameof(query.ProvinciaId), "Seleccioná una provincia válida.");
            return ValidationProblem(ModelState);
        }
        var result = await service.GetLocalidadesAsync(query, ct);
        return result is null ? Problem(statusCode: 404, title: "La provincia no existe o no está activa.") : Ok(result);
    }
}

