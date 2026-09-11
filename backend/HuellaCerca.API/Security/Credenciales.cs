using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using HuellaCerca.INTERFACES.Security;
using HuellaCerca.MODEL;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace HuellaCerca.API.Security;

public sealed class Credenciales(IOptions<JwtSettings> options) : ICredenciales
{
    private readonly PasswordHasher<object> hasher = new(Options.Create(new PasswordHasherOptions { IterationCount = 210000 }));
    private readonly object passwordUser = new();
    public int RefreshDias => options.Value.RefreshDays;
    public string HashPassword(string password) => hasher.HashPassword(passwordUser, password);
    public bool VerifyPassword(string hash, string password) => hasher.VerifyHashedPassword(passwordUser, hash, password) != PasswordVerificationResult.Failed;
    public (string Token, DateTime Expira) CrearAccessToken(Usuario usuario, Guid sesionId)
    {
        var settings = options.Value;
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(settings.AccessMinutes);
        var claims = new[] { new Claim("sub", usuario.Id.ToString()), new Claim("mascoteroId", usuario.MascoteroId.ToString()),
            new Claim("sid", sesionId.ToString()), new Claim("jti", Guid.NewGuid().ToString()) };
        var token = new JwtSecurityToken(settings.Issuer, settings.Audience, claims, now, expires,
            new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.Key)), SecurityAlgorithms.HmacSha256));
        return (new JwtSecurityTokenHandler().WriteToken(token), expires);
    }
}

