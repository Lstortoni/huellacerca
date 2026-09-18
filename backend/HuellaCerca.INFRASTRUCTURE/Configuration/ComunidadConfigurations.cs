using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class UsuarioConfiguration : IEntityTypeConfiguration<Usuario>
{
    public void Configure(EntityTypeBuilder<Usuario> b)
    {
        b.ToTable("usuarios"); b.HasKey(x => x.Id);
        b.Property(x => x.Email).HasMaxLength(254).IsRequired(); b.HasIndex(x => x.Email).IsUnique();
        b.Property(x => x.PasswordHash).HasMaxLength(512).IsRequired();
        b.HasOne(x => x.Mascotero).WithOne(x => x.Usuario).HasForeignKey<Usuario>(x => x.MascoteroId).OnDelete(DeleteBehavior.Restrict);
    }
}
public sealed class MascoteroConfiguration : IEntityTypeConfiguration<Mascotero>
{
    public void Configure(EntityTypeBuilder<Mascotero> b)
    {
        b.ToTable("mascoteros"); b.HasKey(x => x.Id);
        b.Property(x => x.Nombre).HasMaxLength(100).IsRequired(); b.Property(x => x.Apellido).HasMaxLength(100).IsRequired();
        b.Property(x => x.Telefono).HasMaxLength(40);
        b.HasOne(x => x.Localidad).WithMany().HasForeignKey(x => x.LocalidadId).OnDelete(DeleteBehavior.Restrict);
    }
}
public sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> b)
    {
        b.ToTable("refresh_tokens"); b.HasKey(x => x.Id);
        b.Property(x => x.TokenHash).HasMaxLength(64).IsRequired(); b.HasIndex(x => x.TokenHash).IsUnique();
        b.HasIndex(x => x.SesionId); b.HasIndex(x => x.FechaExpiracion);
        b.Property(x => x.FechaRevocacion).IsConcurrencyToken();
        b.HasOne(x => x.Usuario).WithMany(x => x.RefreshTokens).HasForeignKey(x => x.UsuarioId).OnDelete(DeleteBehavior.Cascade);
    }
}
public sealed class RubroConfiguration : IEntityTypeConfiguration<Rubro>
{
    public void Configure(EntityTypeBuilder<Rubro> b)
    {
        b.ToTable("rubros"); b.HasKey(x => x.Id); b.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
        b.HasIndex(x => x.Nombre).IsUnique();
        var names = new[] { "Veterinaria", "Peluquería", "Paseador", "Cuidado y guardería", "Tienda de mascotas", "Otro" };
        b.HasData(names.Select((name, i) => new Rubro { Id = Guid.Parse($"10000000-0000-0000-0000-{i + 1:000000000000}"), Nombre = name }));
    }
}
public sealed class PrestadorConfiguration : IEntityTypeConfiguration<PrestadorServicio>
{
    public void Configure(EntityTypeBuilder<PrestadorServicio> b)
    {
        b.ToTable("prestadores_servicio"); b.HasKey(x => x.Id);
        b.Property(x => x.Nombre).HasMaxLength(150).IsRequired(); b.Property(x => x.NombreBusqueda).HasMaxLength(150).IsRequired();
        b.Property(x => x.Direccion).HasMaxLength(250); b.Property(x => x.Telefono).HasMaxLength(40); b.Property(x => x.Enlace).HasMaxLength(500);
        b.HasIndex(x => new { x.RubroId, x.LocalidadId });
        b.HasOne(x => x.Rubro).WithMany().HasForeignKey(x => x.RubroId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.Localidad).WithMany().HasForeignKey(x => x.LocalidadId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.MascoteroCreador).WithMany().HasForeignKey(x => x.MascoteroCreadorId).OnDelete(DeleteBehavior.Restrict);
    }
}
public sealed class RecomendacionConfiguration : IEntityTypeConfiguration<Recomendacion>
{
    public void Configure(EntityTypeBuilder<Recomendacion> b)
    {
        b.ToTable("recomendaciones"); b.HasKey(x => x.Id);
        b.HasIndex(x => new { x.MascoteroId, x.PrestadorServicioId }).IsUnique();
        b.Property(x => x.FechaActualizacion).IsConcurrencyToken();
        b.HasIndex(x => x.FechaCreacion);
        b.HasOne(x => x.Mascotero).WithMany(x => x.Recomendaciones).HasForeignKey(x => x.MascoteroId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.PrestadorServicio).WithMany(x => x.Recomendaciones).HasForeignKey(x => x.PrestadorServicioId).OnDelete(DeleteBehavior.Restrict);
    }
}
