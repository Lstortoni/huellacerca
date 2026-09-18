using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Npgsql;
namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class RecomendacionRepository(AppDbContext db) : IRecomendacionRepository
{
    private IQueryable<PrestadorServicio> DatosPrestadores => db.PrestadoresServicio.Include(x => x.Rubro).Include(x => x.Localidad);
    private IQueryable<PrestadorServicio> Prestadores => DatosPrestadores
        .Where(x => x.Activo && x.Rubro.Activo && x.Localidad.Activa && x.Localidad.Provincia.Activa && x.Localidad.Provincia.Pais.Activo);
    private IQueryable<Recomendacion> Recomendaciones => db.Recomendaciones
        .Include(x => x.Aspectos).ThenInclude(x => x.AspectoRecomendacion);
    public async Task<IReadOnlyList<Rubro>> RubrosAsync(CancellationToken ct) =>
        await db.Rubros.AsNoTracking().Where(x => x.Activo).OrderBy(x => x.Nombre).ToListAsync(ct);
    public async Task<IReadOnlyList<AspectoRecomendacion>> AspectosAsync(CancellationToken ct) =>
        await db.AspectosRecomendacion.AsNoTracking().Where(x => x.Activo).OrderBy(x => x.Id).ToListAsync(ct);
    public Task<bool> RubroActivoAsync(Guid id, CancellationToken ct) => db.Rubros.AnyAsync(x => x.Id == id && x.Activo, ct);
    public Task<PrestadorServicio?> PrestadorAsync(Guid id, CancellationToken ct) => Prestadores.SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<IReadOnlyList<PrestadorDto>> SimilaresAsync(SimilaresQuery query, CancellationToken ct)
    {
        var text = TextoBusqueda.Normalizar(query.Nombre);
        var items = await Prestadores.AsNoTracking().Where(x => x.RubroId == query.RubroId && x.LocalidadId == query.LocalidadId)
            .Where(x => x.NombreBusqueda.Contains(text) || EF.Functions.TrigramsSimilarity(x.NombreBusqueda, text) >= 0.25)
            .OrderByDescending(x => EF.Functions.TrigramsSimilarity(x.NombreBusqueda, text)).ThenBy(x => x.Nombre).ThenBy(x => x.Id)
            .Take(query.Limite).ToListAsync(ct);
        return await ConConteosAsync(items, ct);
    }
    public async Task<IReadOnlyList<PrestadorDto>> ResumenesAsync(IReadOnlyList<Guid> ids, CancellationToken ct) =>
        await ConConteosAsync(await DatosPrestadores.AsNoTracking().Where(x => ids.Contains(x.Id)).ToListAsync(ct), ct);
    private async Task<IReadOnlyList<PrestadorDto>> ConConteosAsync(List<PrestadorServicio> items, CancellationToken ct)
    {
        var ids = items.Select(x => x.Id).ToArray();
        if (ids.Length == 0) return [];
        // Agregaciones por página: no cargar todas las recomendaciones ni consultar por cada tarjeta.
        var cantidades = await db.Recomendaciones.Where(x => ids.Contains(x.PrestadorServicioId))
            .GroupBy(x => x.PrestadorServicioId).Select(g => new { Id = g.Key, Total = g.Count() }).ToDictionaryAsync(x => x.Id, x => x.Total, ct);
        var aspectos = await db.RecomendacionesAspectos.Where(x => ids.Contains(x.Recomendacion.PrestadorServicioId))
            .GroupBy(x => new { x.Recomendacion.PrestadorServicioId, x.AspectoRecomendacionId, x.AspectoRecomendacion.Nombre })
            .Select(g => new { PrestadorId = g.Key.PrestadorServicioId, Id = g.Key.AspectoRecomendacionId,
                g.Key.Nombre, Cantidad = g.Count() }).ToListAsync(ct);
        return items.Select(p => new PrestadorDto(p.Id, p.Nombre, p.RubroId, p.Rubro.Nombre, p.LocalidadId,
            p.Localidad.Nombre, p.Direccion, p.Telefono, p.Enlace, cantidades.GetValueOrDefault(p.Id),
            aspectos.Where(a => a.PrestadorId == p.Id).OrderByDescending(a => a.Cantidad).ThenBy(a => a.Nombre)
                .Select(a => new AspectoConteoDto(a.Id, a.Nombre, a.Cantidad)).ToList())).ToList();
    }
    public async Task<(IReadOnlyList<PrestadorDto> Items, int Total)> BuscarPrestadoresAsync(RecomendacionesQuery q, CancellationToken ct)
    {
        // El listado público ofrece servicios recomendados. Similares conserva
        // las fichas sin votos para poder volver a recomendarlas sin duplicarlas.
        var query = Prestadores.AsNoTracking().Where(x => x.Recomendaciones.Any());
        if (q.RubroId.HasValue) query = query.Where(x => x.RubroId == q.RubroId);
        if (q.LocalidadId.HasValue) query = query.Where(x => x.LocalidadId == q.LocalidadId);
        if (q.ProvinciaId.HasValue) query = query.Where(x => x.Localidad.ProvinciaId == q.ProvinciaId);
        if (!string.IsNullOrWhiteSpace(q.Busqueda))
        {
            var text = TextoBusqueda.Normalizar(q.Busqueda);
            query = query.Where(x => x.NombreBusqueda.Contains(text));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderByDescending(x => x.Recomendaciones.Count).ThenBy(x => x.Nombre).ThenBy(x => x.Id)
            .Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina).ToListAsync(ct);
        return (await ConConteosAsync(items, ct), total);
    }
    public Task<Recomendacion?> PorIdAsync(Guid id, CancellationToken ct) => Recomendaciones.SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<(IReadOnlyList<MascoteroRecomiendaDto> Items, int Total)> RecomendadoresAsync(Guid prestadorId, RecomendadoresQuery q, CancellationToken ct)
    {
        var query = db.Recomendaciones.AsNoTracking().Where(x => x.PrestadorServicioId == prestadorId);
        var total = await query.CountAsync(ct);
        var items = await query.OrderByDescending(x => x.FechaCreacion).ThenBy(x => x.Id)
            .Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina)
            .Select(x => new MascoteroRecomiendaDto(x.Mascotero.Nombre)).ToListAsync(ct);
        return (items, total);
    }
    public async Task<(IReadOnlyList<Recomendacion> Items, int Total)> MiasAsync(Guid mascoteroId, RecomendacionesQuery q, CancellationToken ct)
    {
        var query = Recomendaciones.AsNoTracking().Where(x => x.MascoteroId == mascoteroId);
        if (q.PrestadorServicioId.HasValue) query = query.Where(x => x.PrestadorServicioId == q.PrestadorServicioId);
        var total = await query.CountAsync(ct);
        var items = await query.OrderByDescending(x => x.FechaCreacion).ThenBy(x => x.Id)
            .Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina).ToListAsync(ct);
        return (items, total);
    }
    public async Task<(Recomendacion Item, bool Creada)> CrearUnicaAsync(Recomendacion item, CancellationToken ct)
    {
        var existente = await Recomendaciones.SingleOrDefaultAsync(x =>
            x.MascoteroId == item.MascoteroId && x.PrestadorServicioId == item.PrestadorServicioId, ct);
        if (existente is not null) return (existente, false);
        db.Entry(item).State = EntityState.Added;
        if (db.Entry(item.PrestadorServicio).State == EntityState.Detached) db.PrestadoresServicio.Add(item.PrestadorServicio);
        try { await GuardarAsync(ct); return (item, true); }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException {
            SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: "IX_recomendaciones_MascoteroId_PrestadorServicioId" })
        {
            // SaveChanges revirtió su transacción; devolvemos el voto que ganó la carrera.
            db.ChangeTracker.Clear();
            existente = await Recomendaciones.SingleOrDefaultAsync(x =>
                x.MascoteroId == item.MascoteroId && x.PrestadorServicioId == item.PrestadorServicioId, ct);
            if (existente is null) throw new AppException(409, "La recomendación cambió. Volvé a consultar.");
            return (existente, false);
        }
    }
    public void Eliminar(Recomendacion item) => db.Recomendaciones.Remove(item);
    public async Task GuardarAsync(CancellationToken ct)
    {
        foreach (var entry in db.ChangeTracker.Entries<PrestadorServicio>().Where(x => x.State is EntityState.Added or EntityState.Modified))
            entry.Entity.NombreBusqueda = TextoBusqueda.Normalizar(entry.Entity.Nombre);
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new AppException(409, "La recomendación cambió o fue eliminada. Volvé a consultar."); }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException {
            SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: "PK_recomendaciones_aspectos" })
        {
            // Dos ediciones pueden insertar el mismo vínculo antes del UPDATE del voto.
            // La transacción se revierte completa, sin duplicar aspectos ni perder selecciones.
            throw new AppException(409, "Los aspectos cambiaron en otra solicitud. Volvé a consultar.");
        }
    }
}
