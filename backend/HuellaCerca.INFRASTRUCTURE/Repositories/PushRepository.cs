using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class PushRepository(AppDbContext db) : IPushRepository
{
    public async Task RegistrarAsync(Guid instalacion, Guid autor, Guid sesion, RegistrarDispositivoRequest request, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        // Registro poco frecuente: serializa altas y cambios de cuenta/token para respetar unicidad.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(72409102)", ct);
        var now = DateTime.UtcNow;
        if (!await db.RefreshTokens.AnyAsync(x => x.SesionId == sesion && x.Usuario.MascoteroId == autor
            && x.Usuario.Activo && x.VersionSeguridad == x.Usuario.VersionSeguridad
            && x.FechaRevocacion == null && x.FechaExpiracion > now, ct))
            throw new AppException(401, "La sesión no está activa.");
        await db.DispositivosPush.Where(x => x.Token == request.Token && x.Id != instalacion && x.Activo)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Activo, false), ct);
        var device = await db.DispositivosPush.SingleOrDefaultAsync(x => x.Id == instalacion, ct);
        if (device is null)
        {
            device = new DispositivoPush { Id = instalacion };
            db.DispositivosPush.Add(device);
        }
        if (device.MascoteroId != autor || device.SesionId != sesion || device.Token != request.Token || !device.Activo)
            device.Version = Guid.NewGuid();
        device.MascoteroId = autor;
        device.SesionId = sesion;
        device.Token = request.Token;
        device.Plataforma = request.Plataforma;
        device.Activo = true;
        device.FechaActualizacion = now;
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
    }

    public async Task DesactivarAsync(Guid instalacion, Guid autor, Guid sesion, CancellationToken ct) =>
        await db.DispositivosPush.Where(x => x.Id == instalacion && x.MascoteroId == autor && x.SesionId == sesion)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Activo, false)
                .SetProperty(x => x.FechaActualizacion, DateTime.UtcNow), ct);

    public async Task<TrabajoPush?> ReservarAsync(CancellationToken ct)
    {
        // Reserva corta persistida. Si el proceso cae, otro puede retomar a los 2 minutos.
        // Cada envío tiene un timeout menor que la reserva.
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var now = DateTime.UtcNow;
        var filas = await db.EnviosPush.FromSqlInterpolated($"""
            SELECT * FROM "EnviosPush"
            WHERE "FechaFinalizacion" IS NULL AND "ProximoIntento" <= {now}
            ORDER BY "ProximoIntento", "Id" LIMIT 1 FOR UPDATE SKIP LOCKED
            """).ToListAsync(ct);
        var envio = filas.SingleOrDefault();
        if (envio is null) return null;
        var n = await db.Notificaciones.AsNoTracking().SingleAsync(x => x.Id == envio.NotificacionId, ct);
        var d = await db.DispositivosPush.AsNoTracking().SingleAsync(x => x.Id == envio.DispositivoPushId, ct);
        var vigente = d.Activo && d.Version == envio.VersionDispositivo && d.MascoteroId == n.MascoteroId
            && await db.RefreshTokens.AnyAsync(x => x.SesionId == d.SesionId && x.Usuario.MascoteroId == d.MascoteroId
                && x.Usuario.Activo && x.VersionSeguridad == x.Usuario.VersionSeguridad
                && x.FechaRevocacion == null && x.FechaExpiracion > now, ct);
        if (!vigente || n.FechaLectura != null || envio.FechaCreacion < now.AddHours(-24) || envio.Intentos >= 5)
        {
            envio.FechaFinalizacion = now;
            envio.Resultado = !vigente ? "DispositivoDesvinculado" : n.FechaLectura != null ? "YaLeida" : "Expirado";
            await db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            // El worker vuelve a consultar en su siguiente ciclo.
            return null;
        }
        envio.Reserva = Guid.NewGuid();
        envio.Intentos++;
        envio.ProximoIntento = now.AddMinutes(2);
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return new(envio.Id, envio.Reserva.Value, d.Id, d.Version, d.Token, n.MascoteroId,
            n.Id, n.PublicacionCoincidenteId, n.Titulo, n.Mensaje, envio.Intentos, envio.FechaCreacion);
    }

    public async Task CompletarAsync(TrabajoPush trabajo, ResultadoPush resultado, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var finalizar = resultado != ResultadoPush.Reintentar || trabajo.Intentos >= 5;
        var now = DateTime.UtcNow;
        var actualizado = await db.EnviosPush.Where(x => x.Id == trabajo.Id && x.Reserva == trabajo.Reserva
                && x.FechaFinalizacion == null)
            .ExecuteUpdateAsync(s => s
                .SetProperty(x => x.FechaFinalizacion, finalizar ? (DateTime?)now : null)
                .SetProperty(x => x.Resultado, resultado == ResultadoPush.Reintentar && finalizar ? "ReintentosAgotados" : resultado.ToString())
                .SetProperty(x => x.ProximoIntento, now.AddSeconds(Math.Min(3600, 30 * Math.Pow(2, trabajo.Intentos))))
                .SetProperty(x => x.Reserva, (Guid?)null), ct);
        if (actualizado > 0 && resultado == ResultadoPush.TokenInvalido)
            await db.DispositivosPush.Where(x => x.Id == trabajo.DispositivoId && x.Version == trabajo.VersionDispositivo)
                .ExecuteUpdateAsync(s => s.SetProperty(x => x.Activo, false), ct);
        await tx.CommitAsync(ct);
    }
}
