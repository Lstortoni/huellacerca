using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

public sealed class AuthRepository(AppDbContext db) : IAuthRepository
{
    public Task<Usuario?> PorEmailAsync(string email, CancellationToken ct) => db.Usuarios.Include(x => x.Mascotero).SingleOrDefaultAsync(x => x.Email == email, ct);
    public Task<Usuario?> PorIdAsync(Guid id, CancellationToken ct) => db.Usuarios.Include(x => x.Mascotero).SingleOrDefaultAsync(x => x.Id == id, ct);
    public Task<bool> LocalidadActivaAsync(Guid id, CancellationToken ct) => db.Localidades.AnyAsync(x => x.Id == id && x.Activa && x.Provincia.Activa && x.Provincia.Pais.Activo, ct);
    public void Agregar(Usuario usuario) => db.Usuarios.Add(usuario);
    public void Agregar(RefreshToken token) => db.RefreshTokens.Add(token);
    public Task<RefreshToken?> BuscarRefreshAsync(string hash, CancellationToken ct) => db.RefreshTokens.Include(x => x.Usuario).ThenInclude(x => x.Mascotero).SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
    public Task RevocarSesionAsync(Guid sesionId, DateTime ahora, CancellationToken ct) =>
        db.RefreshTokens.Where(x => x.SesionId == sesionId && x.FechaRevocacion == null)
            .ExecuteUpdateAsync(set => set.SetProperty(x => x.FechaRevocacion, ahora), ct);
    public async Task GuardarAsync(CancellationToken ct)
    {
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException)
        {
            db.ChangeTracker.Clear();
            throw new AppException(401, "La sesión ya fue renovada o revocada.");
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: "IX_usuarios_Email" })
        { throw new AppException(409, "El email ya está registrado."); }
    }
}

