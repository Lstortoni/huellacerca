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
    public Task<Localidad?> GetLocalidadActivaAsync(Guid id, CancellationToken ct) =>
        db.Localidades.AsNoTracking().Include(x => x.Provincia)
            .SingleOrDefaultAsync(x => x.Id == id && x.Activa && x.Provincia.Activa && x.Provincia.Pais.Activo, ct);
    public async Task<(IReadOnlyList<Localidad> Items, int Total)> GetLocalidadesAsync(
        Guid? provinciaId, string? busqueda, int pagina, int tamanoPagina, CancellationToken ct)
    {
        var query = db.Localidades.AsNoTracking().Include(x => x.Provincia)
            .Where(x => x.Activa && x.Provincia.Activa && x.Provincia.Pais.Activo);
        if (provinciaId is { } provincia) query = query.Where(x => x.ProvinciaId == provincia);
        var normalized = string.IsNullOrWhiteSpace(busqueda) ? null : TextoBusqueda.Normalizar(busqueda);
        if (normalized is not null) query = query.Where(x => x.NombreBusqueda.Contains(normalized));
        var total = await query.CountAsync(ct);
        // Primero las que empiezan con lo escrito ("La Pl" → La Plata antes que Villa La Plata).
        var ordenada = normalized is null
            ? query.OrderBy(x => x.Nombre)
            : query.OrderBy(x => x.NombreBusqueda.StartsWith(normalized) ? 0 : 1).ThenBy(x => x.Nombre);
        var items = await ordenada.ThenBy(x => x.Id)
            .Skip((pagina - 1) * tamanoPagina).Take(tamanoPagina).ToListAsync(ct);
        return (items, total);
    }
}

