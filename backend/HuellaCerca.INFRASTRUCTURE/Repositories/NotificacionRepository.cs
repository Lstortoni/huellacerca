using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.CONTRACT.Ubicacion;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class NotificacionRepository(AppDbContext db) : INotificacionRepository
{
    public async Task<PaginaDto<NotificacionDto>> ListarAsync(Guid autor, NotificacionesQuery query, CancellationToken ct)
    {
        var rows = db.Notificaciones.AsNoTracking().Where(x => x.MascoteroId == autor);
        if (query.SoloNoLeidas) rows = rows.Where(x => x.FechaLectura == null);
        var total = await rows.CountAsync(ct);
        var items = await rows.OrderByDescending(x => x.FechaCreacion).ThenBy(x => x.Id)
            .Skip((query.Pagina - 1) * query.TamanoPagina).Take(query.TamanoPagina)
            .Select(x => new NotificacionDto(x.Id, x.PublicacionId, x.PublicacionCoincidenteId,
                x.Titulo, x.Mensaje, x.FechaCreacion, x.FechaLectura)).ToListAsync(ct);
        return new(items, total, query.Pagina, query.TamanoPagina);
    }

    public Task<int> ContarAsync(Guid autor, CancellationToken ct) =>
        db.Notificaciones.CountAsync(x => x.MascoteroId == autor && x.FechaLectura == null, ct);

    public async Task<bool> LeerAsync(Guid autor, Guid id, CancellationToken ct)
    {
        var rows = db.Notificaciones.Where(x => x.Id == id && x.MascoteroId == autor);
        if (await rows.Where(x => x.FechaLectura == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.FechaLectura, DateTime.UtcNow), ct) > 0) return true;
        return await rows.AnyAsync(ct); // Repetir la lectura es válido; no cambia su fecha original.
    }

    public async Task LeerTodasAsync(Guid autor, CancellationToken ct) =>
        await db.Notificaciones.Where(x => x.MascoteroId == autor && x.FechaLectura == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.FechaLectura, DateTime.UtcNow), ct);

    public async Task<bool> ProcesarLoteAsync(CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        // Serializa únicamente estos lotes entre instancias de la API. Se libera incluso si el proceso cae.
        var obtenido = await db.Database.SqlQueryRaw<bool>(
            "SELECT pg_try_advisory_xact_lock(72409101) AS \"Value\"").SingleAsync(ct);
        if (!obtenido) return false;
        var trabajo = await db.NotificacionesPendientes.OrderBy(x => x.FechaCreacion)
            .ThenBy(x => x.PublicacionId).FirstOrDefaultAsync(ct);
        if (trabajo is null) return false;
        var origen = await db.PublicacionesMascotas.AsNoTracking().SingleAsync(x => x.Id == trabajo.PublicacionId, ct);
        // No depende de la primera página del listado. Cada lote omite parejas ya procesadas.
        var candidatos = await CoincidenciasConsulta.Aplicar(db.PublicacionesMascotas.AsNoTracking(), origen)
            .Where(x => x.MascoteroId != origen.MascoteroId
                && !db.Notificaciones.Any(n => n.MascoteroId == origen.MascoteroId
                    && n.PublicacionId == origen.Id && n.PublicacionCoincidenteId == x.Id))
            .OrderBy(x => x.Id).Take(100).Select(x => new { x.Id, x.MascoteroId }).ToListAsync(ct);
        foreach (var candidato in candidatos)
        {
            await InsertarAsync(origen.MascoteroId, origen.Id, candidato.Id, ct);
            await InsertarAsync(candidato.MascoteroId, candidato.Id, origen.Id, ct);
        }
        if (candidatos.Count < 100) db.NotificacionesPendientes.Remove(trabajo);
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return true;
    }

    private Task<int> InsertarAsync(Guid autor, Guid propia, Guid otra, CancellationToken ct)
    {
        var n = new Notificacion { MascoteroId = autor, PublicacionId = propia, PublicacionCoincidenteId = otra };
        return db.Database.ExecuteSqlInterpolatedAsync($"""
            INSERT INTO "Notificaciones" ("Id", "MascoteroId", "PublicacionId", "PublicacionCoincidenteId", "Titulo", "Mensaje", "FechaCreacion", "FechaLectura")
            VALUES ({n.Id}, {autor}, {propia}, {otra}, {n.Titulo}, {n.Mensaje}, {n.FechaCreacion}, NULL)
            ON CONFLICT ("MascoteroId", "PublicacionId", "PublicacionCoincidenteId") DO NOTHING
            """, ct);
    }
}
