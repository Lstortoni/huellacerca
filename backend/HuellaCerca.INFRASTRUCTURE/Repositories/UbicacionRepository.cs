using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class UbicacionRepository(AppDbContext db) : IUbicacionRepository
{
    public async Task<IReadOnlyList<Pais>> GetPaisesAsync(CancellationToken ct) =>
        await db.Paises.AsNoTracking().Where(x => x.Activo).OrderBy(x => x.Nombre).ToListAsync(ct);
    public async Task<IReadOnlyList<Provincia>> GetProvinciasAsync(string paisCodigo, CancellationToken ct) =>
        await db.Provincias.AsNoTracking().Where(x => x.Activa && x.Pais.Activo && x.PaisCodigo == paisCodigo)
            .OrderBy(x => x.Nombre).ToListAsync(ct);
    public Task<bool> ProvinciaActivaExisteAsync(Guid id, CancellationToken ct) =>
        db.Provincias.AnyAsync(x => x.Id == id && x.Activa && x.Pais.Activo, ct);
    public async Task<(IReadOnlyList<Localidad> Items, int Total)> GetLocalidadesAsync(
        Guid provinciaId, string? busqueda, int pagina, int tamanoPagina, CancellationToken ct)
    {
        var query = db.Localidades.AsNoTracking().Where(x => x.ProvinciaId == provinciaId && x.Activa && x.Provincia.Activa && x.Provincia.Pais.Activo);
        if (!string.IsNullOrWhiteSpace(busqueda))
        {
            var normalized = TextoBusqueda.Normalizar(busqueda);
            query = query.Where(x => x.NombreBusqueda.Contains(normalized));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(x => x.Nombre).ThenBy(x => x.Id)
            .Skip((pagina - 1) * tamanoPagina).Take(tamanoPagina).ToListAsync(ct);
        return (items, total);
    }
}

