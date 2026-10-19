using HuellaCerca.API.Email;
using HuellaCerca.API.Security;
using HuellaCerca.CONTRACT.Auth;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace HuellaCerca.API.Controllers;

[ApiController, Route("api/auth"), AllowAnonymous, EnableRateLimiting("recuperacion")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class RecuperacionController(IRecuperacionService service, ColaRecuperacion cola,
    IOptions<RecuperacionOptions> options) : ControllerBase
{
    private void ComprobarHabilitado()
    {
        if (!options.Value.Enabled) throw new AppException(503, "La recuperación de contraseña no está habilitada.");
    }

    [HttpPost("forgot-password")]
    public IActionResult Solicitar(ForgotPasswordRequest request)
    {
        ComprobarHabilitado();
        if (!cola.Agregar(request.Email.Trim().ToLowerInvariant()))
            throw new AppException(503, "El servicio está ocupado. Intentá nuevamente más tarde.");
        return Accepted(new { mensaje = "Si existe una cuenta activa con ese email, recibirás las instrucciones.", reintentarEnSegundos = 60 });
    }

    [HttpPost("verify-reset-code")]
    public Task<PermisoRecuperacionDto> Verificar(VerifyResetCodeRequest request, CancellationToken ct)
    {
        ComprobarHabilitado();
        return service.VerificarAsync(request, ct);
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> Restablecer(ResetPasswordRequest request, CancellationToken ct)
    {
        ComprobarHabilitado();
        await service.RestablecerAsync(request, ct);
        return Ok(new { mensaje = "Tu contraseña se actualizó correctamente." });
    }
}
