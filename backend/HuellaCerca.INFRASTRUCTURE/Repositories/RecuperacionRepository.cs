using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class RecuperacionRepository(AppDbContext db) : IRecuperacionRepository
{
    // Todas las operaciones bloquean primero el usuario, incluso cuando aún no existe solicitud.
    // Esto serializa reenvíos, intentos y consumo entre distintas instancias de la API.
    private Task<Usuario?> BloquearAsync(string email, CancellationToken ct) => db.Usuarios
        .FromSqlInterpolated($"SELECT * FROM usuarios WHERE \"Email\" = {email} FOR UPDATE")
        .SingleOrDefaultAsync(ct);

    public async Task<bool> PrepararAsync(string email, Guid codigoId, string codigoHash, DateTime ahora, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var usuario = await BloquearAsync(email, ct);
        if (usuario is not { Activo: true }) return false;
        var r = await db.RecuperacionesPassword.SingleOrDefaultAsync(x => x.UsuarioId == usuario.Id, ct);
        if (r is null)
        {
            r = new RecuperacionPassword { UsuarioId = usuario.Id, VentanaEnvios = ahora };
            db.RecuperacionesPassword.Add(r);
        }
        else if (r.FechaSolicitud.AddSeconds(60) > ahora) return false;
        if (r.VentanaEnvios.AddHours(1) <= ahora) { r.VentanaEnvios = ahora; r.Envios = 0; }
        if (r.Envios >= 3) return false;
        r.Envios++;
        r.CodigoId = codigoId; r.CodigoHash = codigoHash;
        r.FechaSolicitud = ahora; r.FechaExpiracion = ahora.AddMinutes(10);
        r.IntentosFallidos = 0; r.CodigoVerificado = false;
        r.PermisoHash = null; r.PermisoExpira = null; r.FechaUso = null;
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return true;
    }

    public async Task<bool> VerificarAsync(string email, Func<Guid, string, bool> verificarHash,
        string permisoHash, DateTime ahora, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var usuario = await BloquearAsync(email, ct);
        if (usuario is not { Activo: true }) return false;
        var r = await db.RecuperacionesPassword.SingleOrDefaultAsync(x => x.UsuarioId == usuario.Id, ct);
        if (r is null || r.FechaExpiracion <= ahora || r.IntentosFallidos >= 5 || r.CodigoVerificado || r.FechaUso != null)
            return false;
        var valido = verificarHash(r.CodigoId, r.CodigoHash);
        if (!valido) r.IntentosFallidos++;
        else
        {
            r.CodigoVerificado = true; r.CodigoHash = "";
            r.PermisoHash = permisoHash; r.PermisoExpira = ahora.AddMinutes(10);
        }
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return valido;
    }

    public async Task<bool> ConsumirAsync(string permisoHash, string passwordHash, DateTime ahora, CancellationToken ct)
    {
        // Buscar sólo el email, sin materializar un estado que podría quedar obsoleto al esperar el lock.
        var email = await db.RecuperacionesPassword.Where(x => x.PermisoHash == permisoHash)
            .Select(x => x.Usuario.Email).SingleOrDefaultAsync(ct);
        if (email is null) return false;
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var usuario = await BloquearAsync(email, ct);
        if (usuario is not { Activo: true }) return false;
        var r = await db.RecuperacionesPassword.SingleOrDefaultAsync(x => x.UsuarioId == usuario.Id, ct);
        if (r is null || r.PermisoHash != permisoHash || !r.CodigoVerificado || r.FechaUso != null
            || r.PermisoExpira is null || r.PermisoExpira <= ahora) return false;
        usuario.PasswordHash = passwordHash;
        usuario.VersionSeguridad = Guid.NewGuid();
        r.FechaUso = ahora; r.PermisoHash = null; r.PermisoExpira = null; r.CodigoHash = "";
        await db.RefreshTokens.Where(x => x.UsuarioId == usuario.Id && x.FechaRevocacion == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.FechaRevocacion, ahora), ct);
        await db.DispositivosPush.Where(x => x.MascoteroId == usuario.MascoteroId && x.Activo)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Activo, false), ct);
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return true;
    }
}
