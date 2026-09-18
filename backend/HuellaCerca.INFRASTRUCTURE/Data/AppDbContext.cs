using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.INFRASTRUCTURE.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Pais> Paises => Set<Pais>();
    public DbSet<Provincia> Provincias => Set<Provincia>();
    public DbSet<Localidad> Localidades => Set<Localidad>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Mascotero> Mascoteros => Set<Mascotero>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Rubro> Rubros => Set<Rubro>();
    public DbSet<PrestadorServicio> PrestadoresServicio => Set<PrestadorServicio>();
    public DbSet<Recomendacion> Recomendaciones => Set<Recomendacion>();
    public DbSet<AspectoRecomendacion> AspectosRecomendacion => Set<AspectoRecomendacion>();
    public DbSet<RecomendacionAspecto> RecomendacionesAspectos => Set<RecomendacionAspecto>();
    public DbSet<PublicacionMascota> PublicacionesMascotas => Set<PublicacionMascota>();
    public DbSet<FotoPublicacion> FotosPublicaciones => Set<FotoPublicacion>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.HasPostgresExtension("pg_trgm");
        builder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
