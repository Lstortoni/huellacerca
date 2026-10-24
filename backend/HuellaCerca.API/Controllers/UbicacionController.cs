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
        if (query.ProvinciaId is null && (query.Busqueda?.Trim().Length ?? 0) < 2)
        {
            ModelState.AddModelError(nameof(query.Busqueda), "Seleccioná una provincia o escribí al menos 2 letras.");
            return ValidationProblem(ModelState);
        }
        var result = await service.GetLocalidadesAsync(query, ct);
        return result is null ? Problem(statusCode: 404, title: "La provincia no existe o no está activa.") : Ok(result);
    }

    /// Nombre y provincia de una localidad activa; la app lo usa para mostrar la del perfil.
    [HttpGet("localidades/{id:guid}")]
    [ProducesResponseType(typeof(LocalidadDto), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    public async Task<ActionResult<LocalidadDto>> Localidad(Guid id, CancellationToken ct) =>
        await service.GetLocalidadAsync(id, ct) is { } localidad
            ? Ok(localidad)
            : Problem(statusCode: 404, title: "La localidad no existe o no está activa.");
}

