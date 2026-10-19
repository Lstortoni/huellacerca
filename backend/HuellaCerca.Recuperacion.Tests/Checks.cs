using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.RateLimiting;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;

namespace HuellaCerca.Recuperacion.Tests;

internal static class Checks
{
    private static void Check(bool condition, string message)
    { if (!condition) throw new Exception(message); Console.WriteLine("OK: " + message); }

    public static async Task Main()
    {
        var connection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")!;
        var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options;
        AppDbContext Db() => new(options);
        await using (var db = Db()) await db.Database.MigrateAsync();
        var localidad = new Localidad { GeorefId = "recovery", Nombre = "Prueba", NombreBusqueda = "prueba",
            Provincia = new Provincia { GeorefId = "recovery", Nombre = "Prueba",
                Pais = new Pais { Codigo = "ZZ", Nombre = "Prueba" } } };
        await using (var db = Db()) { db.Localidades.Add(localidad); await db.SaveChangesAsync(); }
        var mail = new FakeEmail();
        using var factory = Factory(mail, true);
        using var client = factory.CreateClient();
        async Task<JsonElement> Post(string path, object body, HttpStatusCode expected = HttpStatusCode.OK)
        {
            using var response = await client.PostAsJsonAsync("/api/auth/" + path, body);
            Check(response.StatusCode == expected, path + " HTTP " + (int)expected);
            return await response.Content.ReadFromJsonAsync<JsonElement>();
        }
        const string email = "recovery@example.invalid";
        var session = await Post("register", new { nombre = "Prueba", apellido = "Correo", email,
            password = "Original-123", passwordConfirm = "Original-123", localidadId = localidad.Id }, HttpStatusCode.Created);
        var access = session.GetProperty("accessToken").GetString()!;
        var refresh = session.GetProperty("refreshToken").GetString()!;
        var userId = session.GetProperty("usuario").GetProperty("id").GetGuid();
        async Task Ajustar(Action<RecuperacionPassword> edit)
        {
            await using var db = Db();
            var r = await db.RecuperacionesPassword.SingleAsync(x => x.UsuarioId == userId);
            edit(r); await db.SaveChangesAsync();
        }
        async Task<string> NuevoCodigo()
        {
            await Ajustar(r => { r.FechaSolicitud = DateTime.UtcNow.AddMinutes(-2); r.VentanaEnvios = DateTime.UtcNow.AddHours(-2); });
            await Post("forgot-password", new { email }, HttpStatusCode.Accepted);
            return await mail.CodigoAsync();
        }
        async Task<HttpStatusCode> Me(string token)
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, "/api/auth/me");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            using var result = await client.SendAsync(request);
            return result.StatusCode;
        }
        Check(await Me(access) == HttpStatusCode.OK, "JWT vigente antes de recuperar");
        var known = await Post("forgot-password", new { email = " RECOVERY@example.invalid " }, HttpStatusCode.Accepted);
        var code = await mail.CodigoAsync();
        var unknown = await Post("forgot-password", new { email = "absent@example.invalid" }, HttpStatusCode.Accepted);
        Check(known.ToString() == unknown.ToString(), "Respuesta genérica idéntica para cuentas existentes y ausentes");
        await using (var db = Db())
        {
            var r = await db.RecuperacionesPassword.SingleAsync();
            Check(r.CodigoHash.Length == 64 && r.CodigoHash != code, "Sólo se persiste código protegido");
        }
        // Los reenvíos inmediatos no reemplazan el código ni multiplican envíos.
        var codigoId = Guid.Empty;
        await using (var db = Db()) codigoId = (await db.RecuperacionesPassword.SingleAsync()).CodigoId;
        await Post("forgot-password", new { email }, HttpStatusCode.Accepted);
        await Task.Delay(250);
        await using (var db = Db()) Check((await db.RecuperacionesPassword.SingleAsync()).CodigoId == codigoId, "Espera de 60 segundos aplicada en servidor");
        var incorrecto = code == "000000" ? "111111" : "000000";
        var fallos = await Task.WhenAll(Enumerable.Range(0, 8).Select(_ => client.PostAsJsonAsync("/api/auth/verify-reset-code", new { email, codigo = incorrecto })));
        Check(fallos.All(x => x.StatusCode == HttpStatusCode.BadRequest), "Intentos simultáneos rechazados");
        foreach (var result in fallos) result.Dispose();
        await using (var db = Db()) Check((await db.RecuperacionesPassword.SingleAsync()).IntentosFallidos == 5, "Máximo cinco intentos, incluso concurrentes");
        await Post("verify-reset-code", new { email, codigo = code }, HttpStatusCode.BadRequest);
        code = await NuevoCodigo();
        await Ajustar(r => r.FechaExpiracion = DateTime.UtcNow.AddSeconds(-1));
        await Post("verify-reset-code", new { email, codigo = code }, HttpStatusCode.BadRequest);
        code = await NuevoCodigo();
        var validaciones = await Task.WhenAll(Enumerable.Range(0, 2).Select(_ => client.PostAsJsonAsync("/api/auth/verify-reset-code", new { email, codigo = code })));
        Check(validaciones.Count(x => x.IsSuccessStatusCode) == 1, "Un código sólo genera una autorización, aun en paralelo");
        var grant = await validaciones.Single(x => x.IsSuccessStatusCode).Content.ReadFromJsonAsync<JsonElement>();
        foreach (var result in validaciones) result.Dispose();
        var token = grant.GetProperty("resetToken").GetString()!;
        Check(await Me(token) == HttpStatusCode.Unauthorized, "Permiso de recuperación no autentica al usuario");
        await Post("reset-password", new { resetToken = token, password = "x", passwordConfirm = "x" }, HttpStatusCode.BadRequest);
        await Post("reset-password", new { resetToken = token, password = "Nueva-123456", passwordConfirm = "Distinta-123" }, HttpStatusCode.BadRequest);
        await Ajustar(r => r.PermisoExpira = DateTime.UtcNow.AddSeconds(-1));
        await Post("reset-password", new { resetToken = token, password = "Nueva-123456", passwordConfirm = "Nueva-123456" }, HttpStatusCode.BadRequest);
        code = await NuevoCodigo();
        grant = await Post("verify-reset-code", new { email, codigo = code });
        var oldGrant = grant.GetProperty("resetToken").GetString()!;
        code = await NuevoCodigo();
        await Post("reset-password", new { resetToken = oldGrant, password = "Nueva-123456", passwordConfirm = "Nueva-123456" }, HttpStatusCode.BadRequest);
        grant = await Post("verify-reset-code", new { email, codigo = code });
        token = grant.GetProperty("resetToken").GetString()!;
        var resets = await Task.WhenAll(Enumerable.Range(0, 2).Select(_ => client.PostAsJsonAsync("/api/auth/reset-password", new { resetToken = token, password = "Nueva-123456", passwordConfirm = "Nueva-123456" })));
        Check(resets.Count(x => x.IsSuccessStatusCode) == 1, "Consumo atómico del permiso: un solo cambio de contraseña");
        foreach (var result in resets) result.Dispose();
        Check(await Me(access) == HttpStatusCode.Unauthorized, "JWT anterior invalidado inmediatamente");
        await Post("refresh", new { refreshToken = refresh }, HttpStatusCode.Unauthorized);
        await Post("login", new { email, password = "Original-123" }, HttpStatusCode.Unauthorized);
        session = await Post("login", new { email, password = "Nueva-123456" });
        Check(await Me(session.GetProperty("accessToken").GetString()!) == HttpStatusCode.OK, "Nueva contraseña permite iniciar sesión");
        // Simula un refresh que leyó la versión anterior antes del cambio y se guardó después.
        const string staleRaw = "stale-session-test-token-with-more-than-32-characters";
        await using (var db = Db())
        {
            db.RefreshTokens.Add(new RefreshToken { UsuarioId = userId, SesionId = Guid.NewGuid(), VersionSeguridad = Guid.Empty,
                TokenHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(staleRaw))),
                FechaCreacion = DateTime.UtcNow, FechaExpiracion = DateTime.UtcNow.AddDays(1) });
            await db.SaveChangesAsync();
        }
        await Post("refresh", new { refreshToken = staleRaw }, HttpStatusCode.Unauthorized);
        await Ajustar(r => { r.Envios = 3; r.VentanaEnvios = DateTime.UtcNow; r.FechaSolicitud = DateTime.UtcNow.AddMinutes(-2); });
        await Post("forgot-password", new { email }, HttpStatusCode.Accepted);
        await Task.Delay(250);
        await using (var db = Db()) Check((await db.RecuperacionesPassword.SingleAsync()).Envios == 3, "Límite por cuenta de tres envíos por hora");
        using var limited = Factory(mail, false);
        using var limitedClient = limited.CreateClient();
        for (var i = 0; i < 10; i++)
        {
            using var response = await limitedClient.PostAsJsonAsync("/api/auth/forgot-password", new { email = "absent@example.invalid" });
            Check(response.StatusCode == HttpStatusCode.Accepted, "Solicitud dentro del límite IP");
        }
        using var excess = await limitedClient.PostAsJsonAsync("/api/auth/forgot-password", new { email });
        Check(excess.StatusCode == HttpStatusCode.TooManyRequests, "Límite IP aplicado a todas las cuentas");
        Console.WriteLine("Recuperación HTTP y PostgreSQL verificados. No se enviaron correos reales.");
    }

    private static WebApplicationFactory<global::Program> Factory(FakeEmail email, bool sinLimite) =>
        new WebApplicationFactory<global::Program>().WithWebHostBuilder(b =>
        {
            b.ConfigureLogging(l => l.ClearProviders());
            b.ConfigureServices(s =>
            {
                s.RemoveAll<IEmailService>();
                s.AddSingleton<IEmailService>(email);
                if (sinLimite) s.Configure<RateLimiterOptions>(o =>
                    o.AddPolicy("recuperacion", _ => RateLimitPartition.GetNoLimiter("pruebas")));
            });
        });
}

internal sealed class FakeEmail : IEmailService
{
    private readonly ConcurrentQueue<string> codigos = new();
    private readonly SemaphoreSlim disponibles = new(0);
    public Task<string?> EnviarAsync(string destinatario, string asunto, string html, string texto, CancellationToken ct = default)
    {
        var codigo = Regex.Match(texto, @"\b[0-9]{6}\b").Value;
        if (codigo.Length != 6) throw new Exception("Falta el código en la plantilla.");
        codigos.Enqueue(codigo); disponibles.Release();
        return Task.FromResult<string?>("fake-message");
    }
    public async Task<string> CodigoAsync()
    {
        if (!await disponibles.WaitAsync(TimeSpan.FromSeconds(10))) throw new Exception("No se procesó el correo simulado.");
        return codigos.TryDequeue(out var codigo) ? codigo : throw new Exception("Cola vacía.");
    }
}
