using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class RecomendacionRepository(AppDbContext db) : IRecomendacionRepository
{
    private IQueryable<PrestadorServicio> Prestadores => db.PrestadoresServicio
        .Include(x => x.Rubro).Include(x => x.Localidad)
        .Where(x => x.Activo && x.Rubro.Activo && x.Localidad.Activa && x.Localidad.Provincia.Activa && x.Localidad.Provincia.Pais.Activo);
    private IQueryable<Recomendacion> Recomendaciones => db.Recomendaciones.Include(x => x.Mascotero)
        .Include(x => x.PrestadorServicio).ThenInclude(x => x.Rubro)
        .Include(x => x.PrestadorServicio).ThenInclude(x => x.Localidad)
        .Where(x => x.PrestadorServicio.Activo && x.PrestadorServicio.Rubro.Activo);
    public async Task<IReadOnlyList<Rubro>> RubrosAsync(CancellationToken ct) => await db.Rubros.AsNoTracking().Where(x => x.Activo).OrderBy(x => x.Nombre).ToListAsync(ct);
    public Task<bool> RubroActivoAsync(Guid id, CancellationToken ct) => db.Rubros.AnyAsync(x => x.Id == id && x.Activo, ct);
    public Task<PrestadorServicio?> PrestadorAsync(Guid id, CancellationToken ct) => Prestadores.SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<IReadOnlyList<PrestadorServicio>> SimilaresAsync(SimilaresQuery query, CancellationToken ct)
    {
        var text = TextoBusqueda.Normalizar(query.Nombre);
        return await Prestadores.AsNoTracking().Where(x => x.RubroId == query.RubroId && x.LocalidadId == query.LocalidadId)
            .Where(x => x.NombreBusqueda.Contains(text) || EF.Functions.TrigramsSimilarity(x.NombreBusqueda, text) >= 0.25)
            .OrderByDescending(x => EF.Functions.TrigramsSimilarity(x.NombreBusqueda, text)).ThenBy(x => x.Nombre).ThenBy(x => x.Id)
            .Take(query.Limite).ToListAsync(ct);
    }
    public Task<Recomendacion?> PorIdAsync(Guid id, CancellationToken ct) => Recomendaciones.SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<(IReadOnlyList<Recomendacion> Items, int Total)> BuscarAsync(RecomendacionesQuery q, CancellationToken ct)
    {
        var query = Recomendaciones.AsNoTracking();
        if (q.RubroId.HasValue) query = query.Where(x => x.PrestadorServicio.RubroId == q.RubroId);
        if (q.LocalidadId.HasValue) query = query.Where(x => x.PrestadorServicio.LocalidadId == q.LocalidadId);
        if (q.ProvinciaId.HasValue) query = query.Where(x => x.PrestadorServicio.Localidad.ProvinciaId == q.ProvinciaId);
        if (q.MascoteroId.HasValue) query = query.Where(x => x.MascoteroId == q.MascoteroId);
        if (!string.IsNullOrWhiteSpace(q.Busqueda))
        {
            var text = q.Busqueda.Trim().ToLowerInvariant();
            var normalized = TextoBusqueda.Normalizar(q.Busqueda);
            query = query.Where(x => x.Titulo.ToLower().Contains(text) || x.Descripcion.ToLower().Contains(text) || x.PrestadorServicio.NombreBusqueda.Contains(normalized));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderByDescending(x => x.FechaCreacion).ThenBy(x => x.Id)
            .Skip((q.Pagina - 1) * q.TamanoPagina).Take(q.TamanoPagina).ToListAsync(ct);
        return (items, total);
    }
    public void Agregar(Recomendacion item)
    {
        // No marcar como nuevo al prestador compartido ya cargado en el contexto.
        db.Entry(item).State = EntityState.Added;
        if (db.Entry(item.PrestadorServicio).State == EntityState.Detached) db.PrestadoresServicio.Add(item.PrestadorServicio);
    }
    public void Eliminar(Recomendacion item) => db.Recomendaciones.Remove(item);
    public async Task GuardarAsync(CancellationToken ct)
    {
        foreach (var entry in db.ChangeTracker.Entries<PrestadorServicio>().Where(x => x.State is EntityState.Added or EntityState.Modified))
            entry.Entity.NombreBusqueda = TextoBusqueda.Normalizar(entry.Entity.Nombre);
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new AppException(409, "La recomendación cambió o fue eliminada. Volvé a consultar."); }
    }
}

