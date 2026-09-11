using HuellaCerca.CONTRACT.Auth;
using HuellaCerca.INTERFACES.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace HuellaCerca.API.Controllers;

[ApiController]
[Route("api/auth")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class AuthController(IAuthService service) : ControllerBase
{
    [HttpPost("register"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken ct)
    {
        Response.Headers.CacheControl = "no-store";
        return StatusCode(201, await service.RegisterAsync(request, ct));
    }
    [HttpPost("login"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<AuthResponse> Login(LoginRequest request, CancellationToken ct)
    {
        Response.Headers.CacheControl = "no-store";
        return await service.LoginAsync(request, ct);
    }
    [HttpPost("refresh"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<AuthResponse> Refresh(RefreshRequest request, CancellationToken ct)
    {
        Response.Headers.CacheControl = "no-store";
        return await service.RefreshAsync(request.RefreshToken, ct);
    }
    [HttpPost("logout"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Logout(RefreshRequest request, CancellationToken ct)
    {
        await service.LogoutAsync(request.RefreshToken, ct);
        return NoContent();
    }
    [HttpGet("me"), Authorize]
    public Task<UsuarioActualDto> Me(CancellationToken ct) => service.MeAsync(Guid.Parse(User.FindFirst("sub")!.Value), ct);
}
