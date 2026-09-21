using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace HuellaCerca.API.Controllers;

[ApiController, Route("api/publicaciones/{id:guid}/foto")]
public sealed class FotosController(IFotoService service) : ControllerBase
{
    [HttpPut, Authorize, EnableRateLimiting("fotos")]
    [RequestSizeLimit(11 * 1024 * 1024), RequestFormLimits(MultipartBodyLengthLimit = 11 * 1024 * 1024)]
    public async Task<IActionResult> Subir(Guid id, IFormFile archivo, CancellationToken ct)
    {
        if (Request.Form.Files.Count != 1 || archivo.Length == 0) throw new AppException(400, "Seleccioná una única foto.");
        if (archivo.Length > 10 * 1024 * 1024) throw new AppException(413, "La foto no puede superar 10 MB.");
        await using var stream = archivo.OpenReadStream();
        return Ok(await service.SubirAsync(id, Autor, stream, ct));
    }
    [HttpGet, AllowAnonymous]
    public async Task<IActionResult> Leer(Guid id, CancellationToken ct)
    {
        var data = await service.LeerAsync(id, ct);
        // URL estable con versión para Flutter, pero sin servir una foto borrada desde cache compartida.
        Response.Headers.CacheControl = "no-store";
        Response.Headers.XContentTypeOptions = "nosniff";
        return File(data, "image/webp");
    }
    [HttpDelete, Authorize]
    public async Task<IActionResult> Eliminar(Guid id, CancellationToken ct)
    {
        await service.EliminarAsync(id, Autor, ct);
        return NoContent();
    }
    private Guid Autor => Guid.Parse(User.FindFirst("mascoteroId")!.Value);
}
