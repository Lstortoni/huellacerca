using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using HuellaCerca.CONTRACT.Auth;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Security;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.SERVICES;

public sealed class RecuperacionService(IRecuperacionRepository repository, IProtectorRecuperacion protector,
    ICredenciales credenciales, IEmailTemplates templates, IEmailService emailService) : IRecuperacionService
{
    public async Task EnviarCodigoAsync(string email, CancellationToken ct)
    {
        var codigo = RandomNumberGenerator.GetInt32(1_000_000).ToString("D6", CultureInfo.InvariantCulture);
        var id = Guid.NewGuid();
        if (!await repository.PrepararAsync(Normalizar(email), id, protector.ProtegerCodigo(id, codigo), DateTime.UtcNow, ct)) return;
        var contenido = templates.RecuperacionPassword(codigo);
        await emailService.EnviarAsync(Normalizar(email), contenido.Asunto, contenido.Html, contenido.Texto, ct);
    }

    public async Task<PermisoRecuperacionDto> VerificarAsync(VerifyResetCodeRequest request, CancellationToken ct)
    {
        Validar(request);
        var permiso = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var ahora = DateTime.UtcNow;
        if (!await repository.VerificarAsync(Normalizar(request.Email),
            (id, hash) => protector.VerificarCodigo(id, request.Codigo, hash), Hash(permiso), ahora, ct))
            throw new AppException(400, "El código no es válido o venció. Solicitá uno nuevo si agotaste los intentos.");
        return new(permiso, ahora.AddMinutes(10));
    }

    public async Task RestablecerAsync(ResetPasswordRequest request, CancellationToken ct)
    {
        Validar(request);
        var passwordHash = credenciales.HashPassword(request.Password);
        if (!await repository.ConsumirAsync(Hash(request.ResetToken), passwordHash, DateTime.UtcNow, ct))
            throw new AppException(400, "La autorización de recuperación no es válida o venció.");
    }
    private static string Normalizar(string email) => email.Trim().ToLowerInvariant();
    private static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    private static void Validar(object request)
    {
        var errors = new List<ValidationResult>();
        if (!Validator.TryValidateObject(request, new ValidationContext(request), errors, true))
            throw new AppException(400, "Revisá los datos de recuperación y la confirmación de contraseña.");
    }
}
