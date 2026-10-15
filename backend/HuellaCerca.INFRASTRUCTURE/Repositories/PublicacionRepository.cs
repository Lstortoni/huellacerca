using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class PublicacionRepository(AppDbContext db) : IPublicacionRepository
{
    private IQueryable<PublicacionMascota> Publicaciones => db.PublicacionesMascotas
        .Include(x => x.Mascotero)
        .Include(x => x.Localidad).ThenInclude(x => x.Provincia)
        .Include(x => x.Foto);

    public void Agregar(PublicacionMascota publicacion)
    {
        db.PublicacionesMascotas.Add(publicacion);
        db.NotificacionesPendientes.Add(new NotificacionPendiente { PublicacionId = publicacion.Id });
    }

    public Task<PublicacionMascota?> PorIdAsync(Guid id, CancellationToken ct) =>
        Publicaciones.SingleOrDefaultAsync(x => x.Id == id, ct);

    public async Task<(IReadOnlyList<PublicacionMascota> Items, int Total)> BuscarAsync(PublicacionesQuery q, CancellationToken ct)
    {
        var query = Publicaciones.AsNoTracking();
        // Los filtros son exactos y se combinan; null en el aviso no implica coincidencia.
        if (q.Tamano.HasValue) query = query.Where(x => (int?)x.Tamano == q.Tamano);
        if (q.Raza.HasValue) query = query.Where(x => (int?)x.Raza == q.Raza);
        if (q.Pelaje.HasValue) query = query.Where(x => (int?)x.Pelaje == q.Pelaje);
        if (q.ColorPredominante.HasValue) query = query.Where(x => (int?)x.ColorPredominante == q.ColorPredominante);
        if (q.ColorOjos.HasValue) query = query.Where(x => (int?)x.ColorOjos == q.ColorOjos);
        if (q.TipoPublicacion.HasValue) query = query.Where(x => (int)x.TipoPublicacion == q.TipoPublicacion);
        if (q.TipoMascota.HasValue) query = query.Where(x => (int)x.TipoMascota == q.TipoMascota);
        if (q.Estado.HasValue) query = query.Where(x => (int)x.Estado == q.Estado);
        if (q.LocalidadId.HasValue) query = query.Where(x => x.LocalidadId == q.LocalidadId);
        if (q.ProvinciaId.HasValue) query = query.Where(x => x.Localidad.ProvinciaId == q.ProvinciaId);
        if (q.MascoteroId.HasValue) query = query.Where(x => x.MascoteroId == q.MascoteroId);
        if (q.ExcluirMascoteroId.HasValue) query = query.Where(x => x.MascoteroId != q.ExcluirMascoteroId);
        // Adopción usa el día de publicación en Argentina; perdidas/encontradas el del suceso.
        if (q.FechaDesde.HasValue)
        {
            var desdeUtc = DateTime.SpecifyKind(q.FechaDesde.Value.ToDateTime(TimeOnly.MinValue), DateTimeKind.Utc).AddHours(3);
            query = query.Where(x => ((int)x.TipoPublicacion <= 2 && x.FechaSuceso >= q.FechaDesde)
                || ((int)x.TipoPublicacion >= 3 && x.FechaCreacion >= desdeUtc));
        }
        if (q.FechaHasta.HasValue)
        {
            var hastaUtc = q.FechaHasta.Value == DateOnly.MaxValue ? DateTime.SpecifyKind(DateTime.MaxValue, DateTimeKind.Utc)
                : DateTime.SpecifyKind(q.FechaHasta.Value.ToDateTime(TimeOnly.MaxValue), DateTimeKind.Utc).AddHours(3);
            query = query.Where(x => ((int)x.TipoPublicacion <= 2 && x.FechaSuceso <= q.FechaHasta)
                || ((int)x.TipoPublicacion >= 3 && x.FechaCreacion <= hastaUtc));
        }
        if (!string.IsNullOrWhiteSpace(q.Zona))
        {
            var zona = q.Zona.Trim().ToLowerInvariant();
            query = query.Where(x => x.Zona.ToLower().Contains(zona));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderByDescending(x => x.FechaCreacion).ThenBy(x => x.Id)
            .Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina).ToListAsync(ct);
        return (items, total);
    }

    public async Task GuardarAsync(CancellationToken ct)
    {
        foreach (var entry in db.ChangeTracker.Entries<PublicacionMascota>().Where(x => x.State == EntityState.Modified))
            entry.Entity.Version = Guid.NewGuid();
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException)
        { throw new AppException(409, "La publicación cambió o fue eliminada. Volvé a consultar."); }
    }

    public async Task GuardarEdicionAsync(PublicacionMascota publicacion, bool revisarCoincidencias, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        // Mismo bloqueo que usa el worker: no puede borrar el pendiente mientras lo renovamos.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(72409101)", ct);
        await GuardarAsync(ct);
        if (revisarCoincidencias)
        {
            await db.Database.ExecuteSqlInterpolatedAsync($"""
                INSERT INTO "NotificacionesPendientes" ("PublicacionId", "FechaCreacion")
                VALUES ({publicacion.Id}, {DateTime.UtcNow})
                ON CONFLICT ("PublicacionId") DO NOTHING
                """, ct);
        }
        await tx.CommitAsync(ct);
        // La respuesta debe cargar también la nueva localidad/provincia, no la navegación anterior.
        db.ChangeTracker.Clear();
    }

    public async Task<(IReadOnlyList<PublicacionMascota> Items, int Total)> CoincidenciasAsync(
        PublicacionMascota origen, CoincidenciasQuery q, CancellationToken ct)
    {
        // Puntuar en SQL antes de paginar: nunca traer todos los candidatos a memoria.
        var candidatos = CoincidenciasConsulta.Aplicar(db.PublicacionesMascotas.AsNoTracking(), origen)
            .Select(x => new {
                x.Id, x.FechaCreacion,
                Puntos = (origen.Tamano.HasValue && x.Tamano == origen.Tamano ? 1 : 0)
                    + (origen.Raza.HasValue && x.Raza == origen.Raza ? 1 : 0)
                    + (origen.Pelaje.HasValue && x.Pelaje == origen.Pelaje ? 1 : 0)
                    + (origen.ColorPredominante.HasValue && x.ColorPredominante == origen.ColorPredominante ? 1 : 0)
                    + (origen.ColorOjos.HasValue && x.ColorOjos == origen.ColorOjos ? 1 : 0)
            }).Where(x => x.Puntos > 0);
        var total = await candidatos.CountAsync(ct);
        var ids = await candidatos.OrderByDescending(x => x.Puntos).ThenByDescending(x => x.FechaCreacion)
            .ThenBy(x => x.Id).Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina)
            .Select(x => x.Id).ToListAsync(ct);
        var items = await Publicaciones.AsNoTracking().Where(x => ids.Contains(x.Id)).ToListAsync(ct);
        return (items.OrderBy(x => ids.IndexOf(x.Id)).ToList(), total);
    }
}
