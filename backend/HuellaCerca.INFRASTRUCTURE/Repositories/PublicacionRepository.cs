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
        .Include(x => x.Fotografias);

    public void Agregar(PublicacionMascota publicacion) => db.PublicacionesMascotas.Add(publicacion);

    public Task<PublicacionMascota?> PorIdAsync(Guid id, CancellationToken ct) =>
        Publicaciones.SingleOrDefaultAsync(x => x.Id == id, ct);

    public async Task<(IReadOnlyList<PublicacionMascota> Items, int Total)> BuscarAsync(PublicacionesQuery q, CancellationToken ct)
    {
        var query = Publicaciones.AsNoTracking();
        if (q.TipoPublicacion.HasValue) query = query.Where(x => (int)x.TipoPublicacion == q.TipoPublicacion);
        if (q.TipoMascota.HasValue) query = query.Where(x => (int)x.TipoMascota == q.TipoMascota);
        if (q.Estado.HasValue) query = query.Where(x => (int)x.Estado == q.Estado);
        if (q.LocalidadId.HasValue) query = query.Where(x => x.LocalidadId == q.LocalidadId);
        if (q.ProvinciaId.HasValue) query = query.Where(x => x.Localidad.ProvinciaId == q.ProvinciaId);
        if (q.MascoteroId.HasValue) query = query.Where(x => x.MascoteroId == q.MascoteroId);
        if (q.FechaDesde.HasValue) query = query.Where(x => x.FechaSuceso >= q.FechaDesde);
        if (q.FechaHasta.HasValue) query = query.Where(x => x.FechaSuceso <= q.FechaHasta);
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
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException)
        { throw new AppException(409, "La publicación cambió o fue eliminada. Volvé a consultar."); }
    }
}
