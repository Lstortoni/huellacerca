using HuellaCerca.MODEL;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INFRASTRUCTURE.Data;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class FotoRepository(AppDbContext db) : IFotoRepository
{
    public Task<PublicacionMascota?> ObtenerAsync(Guid id, CancellationToken ct) =>
        db.PublicacionesMascotas.AsNoTracking().Include(x => x.Foto).SingleOrDefaultAsync(x => x.Id == id, ct);

    public async Task PrepararAsync(string key, CancellationToken ct)
    {
        db.Set<FotoPendienteLimpieza>().Add(new() { ObjectKey = key, LimpiarDesdeUtc = DateTime.UtcNow.AddHours(1) });
        await db.SaveChangesAsync(ct);
    }

    public async Task ConfirmarAsync(Guid id, Guid? fotoAnterior, FotoPublicacion? foto, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        // Serializa reemplazos y borrados incluso cuando el aviso aún no tiene foto.
        await db.PublicacionesMascotas.FromSqlInterpolated($"SELECT * FROM publicaciones_mascotas WHERE \"Id\" = {id} FOR UPDATE")
            .AsNoTracking().SingleAsync(ct);
        var anterior = await db.FotosPublicaciones.AsNoTracking().SingleOrDefaultAsync(x => x.PublicacionMascotaId == id, ct);
        if (anterior?.Id != fotoAnterior) throw new AppException(409, "La foto cambió. Volvé a abrir el aviso e intentá nuevamente.");
        if (anterior is not null)
        {
            await db.FotosPublicaciones.Where(x => x.PublicacionMascotaId == id).ExecuteDeleteAsync(ct);
            db.Set<FotoPendienteLimpieza>().Add(new() { ObjectKey = anterior.ObjectKey, LimpiarDesdeUtc = DateTime.UtcNow });
        }
        if (foto is not null)
        {
            db.FotosPublicaciones.Add(foto);
            await db.Set<FotoPendienteLimpieza>().Where(x => x.ObjectKey == foto.ObjectKey).ExecuteDeleteAsync(ct);
        }
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
    }

    public async Task<IReadOnlyList<string>> PendientesAsync(CancellationToken ct) =>
        await db.Set<FotoPendienteLimpieza>().AsNoTracking()
            .Where(x => x.LimpiarDesdeUtc <= DateTime.UtcNow && !db.FotosPublicaciones.Any(f => f.ObjectKey == x.ObjectKey))
            .OrderBy(x => x.LimpiarDesdeUtc).Take(20).Select(x => x.ObjectKey).ToListAsync(ct);
    public Task CompletarLimpiezaAsync(string key, CancellationToken ct) =>
        db.Set<FotoPendienteLimpieza>().Where(x => x.ObjectKey == key).ExecuteDeleteAsync(ct);
}
