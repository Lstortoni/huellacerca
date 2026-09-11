using System.Security.Cryptography;
using System.Text;
using HuellaCerca.CONTRACT.Auth;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Security;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;

namespace HuellaCerca.SERVICES;

public sealed class AuthService(IAuthRepository repository, ICredenciales credenciales) : IAuthService
{
    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (await repository.PorEmailAsync(email, ct) is not null) throw new AppException(409, "El email ya está registrado.");
        if (!await repository.LocalidadActivaAsync(request.LocalidadId, ct)) throw new AppException(400, "Seleccioná una localidad activa.");
        var mascotero = new Mascotero { Nombre = request.Nombre.Trim(), Apellido = request.Apellido.Trim(),
            Telefono = request.Telefono?.Trim(), LocalidadId = request.LocalidadId };
        var user = new Usuario { Email = email, PasswordHash = credenciales.HashPassword(request.Password),
            Mascotero = mascotero, MascoteroId = mascotero.Id, UltimoAcceso = DateTime.UtcNow };
        repository.Agregar(user);
        var response = CrearSesion(user);
        // Un SaveChanges: Usuario, Mascotero y sesión se guardan en la misma transacción.
        await repository.GuardarAsync(ct);
        return response;
    }
    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct)
    {
        var user = await repository.PorEmailAsync(request.Email.Trim().ToLowerInvariant(), ct);
        if (user is null || !credenciales.VerifyPassword(user.PasswordHash, request.Password) || !user.Activo)
            throw new AppException(401, "Email o contraseña inválidos.");
        user.UltimoAcceso = DateTime.UtcNow;
        var response = CrearSesion(user);
        await repository.GuardarAsync(ct);
        return response;
    }
    public async Task<AuthResponse> RefreshAsync(string token, CancellationToken ct)
    {
        var current = await repository.BuscarRefreshAsync(Hash(token), ct);
        var now = DateTime.UtcNow;
        if (current is null) throw new AppException(401, "La sesión no se puede renovar.");
        if (current.FechaRevocacion is not null)
        {
            // Reutilización de un token rotado: invalidar todas las renovaciones de esa sesión.
            await repository.RevocarSesionAsync(current.SesionId, now, ct);
            throw new AppException(401, "La sesión no se puede renovar.");
        }
        if (current.FechaExpiracion <= now || !current.Usuario.Activo)
            throw new AppException(401, "La sesión no se puede renovar.");
        current.FechaRevocacion = now;
        var response = CrearSesion(current.Usuario, current.SesionId, current.FechaExpiracion);
        try { await repository.GuardarAsync(ct); }
        catch (AppException ex) when (ex.StatusCode == 401)
        {
            await repository.RevocarSesionAsync(current.SesionId, now, ct);
            throw;
        }
        return response;
    }
    public async Task LogoutAsync(string token, CancellationToken ct)
    {
        var stored = await repository.BuscarRefreshAsync(Hash(token), ct);
        if (stored is not null) await repository.RevocarSesionAsync(stored.SesionId, DateTime.UtcNow, ct);
    }
    public async Task<UsuarioActualDto> MeAsync(Guid usuarioId, CancellationToken ct)
    {
        var user = await repository.PorIdAsync(usuarioId, ct);
        return user is { Activo: true } ? ToDto(user) : throw new AppException(401, "Sesión inválida.");
    }
    private AuthResponse CrearSesion(Usuario user, Guid? sesionId = null, DateTime? expires = null)
    {
        var now = DateTime.UtcNow;
        var raw = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        var token = new RefreshToken { UsuarioId = user.Id, Usuario = user, TokenHash = Hash(raw),
            SesionId = sesionId ?? Guid.NewGuid(), FechaCreacion = now,
            FechaExpiracion = expires ?? now.AddDays(credenciales.RefreshDias) };
        repository.Agregar(token);
        var access = credenciales.CrearAccessToken(user, token.SesionId);
        return new(access.Token, access.Expira, raw, token.FechaExpiracion, ToDto(user));
    }
    private static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    private static UsuarioActualDto ToDto(Usuario user) => new(user.Id, user.Email, user.EmailConfirmado,
        new(user.MascoteroId, user.Mascotero.Nombre, user.Mascotero.Apellido, user.Mascotero.Telefono, user.Mascotero.LocalidadId));
}

