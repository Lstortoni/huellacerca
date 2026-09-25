using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class PublicacionMascotaConfiguration : IEntityTypeConfiguration<PublicacionMascota>
{
    public void Configure(EntityTypeBuilder<PublicacionMascota> b)
    {
        b.ToTable("publicaciones_mascotas", t =>
        {
            t.HasCheckConstraint("CK_publicaciones_mascotas_tipo", "\"TipoPublicacion\" IN (1, 2, 3, 4)");
            t.HasCheckConstraint("CK_publicaciones_mascotas_mascota", "\"TipoMascota\" IN (1, 2, 3)");
            t.HasCheckConstraint("CK_publicaciones_mascotas_estado", "\"Estado\" IN (1, 2)");
            t.HasCheckConstraint("CK_publicaciones_tamano", "\"Tamano\" IS NULL OR \"Tamano\" IN (1, 2, 3)");
            t.HasCheckConstraint("CK_publicaciones_raza", "\"Raza\" IS NULL OR \"Raza\" IN (1, 2)");
            t.HasCheckConstraint("CK_publicaciones_pelaje", "\"Pelaje\" IS NULL OR \"Pelaje\" IN (1, 2, 3)");
            t.HasCheckConstraint("CK_publicaciones_color", "\"ColorPredominante\" IS NULL OR \"ColorPredominante\" IN (1, 2, 3, 4, 5, 6, 7)");
            t.HasCheckConstraint("CK_publicaciones_ojos", "\"ColorOjos\" IS NULL OR \"ColorOjos\" IN (1, 2, 3)");
            t.HasCheckConstraint("CK_publicaciones_caracteristicas_otro", "\"TipoMascota\" <> 3 OR (\"Raza\" IS NULL AND \"Pelaje\" IS NULL AND \"ColorOjos\" IS NULL)");
        });
        b.HasKey(x => x.Id);
        b.Property(x => x.Version).IsConcurrencyToken();
        b.Property(x => x.NombreMascota).HasMaxLength(100);
        b.Property(x => x.Descripcion).HasMaxLength(3000).IsRequired();
        b.Property(x => x.Zona).HasMaxLength(250).IsRequired();
        b.Property(x => x.InformacionContacto).HasMaxLength(500).IsRequired();
        b.Property(x => x.FechaSuceso).HasColumnType("date");
        b.HasOne(x => x.Mascotero).WithMany(x => x.PublicacionesMascotas)
            .HasForeignKey(x => x.MascoteroId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.Localidad).WithMany()
            .HasForeignKey(x => x.LocalidadId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(x => new { x.LocalidadId, x.Estado, x.FechaSuceso });
        b.HasIndex(x => x.FechaCreacion);
    }
}

public sealed class FotoPublicacionConfiguration : IEntityTypeConfiguration<FotoPublicacion>
{
    public void Configure(EntityTypeBuilder<FotoPublicacion> b)
    {
        b.ToTable("fotos_publicaciones");
        b.HasKey(x => x.Id);
        b.Property(x => x.ObjectKey).HasMaxLength(500).IsRequired();
        b.HasOne(x => x.PublicacionMascota).WithOne(x => x.Foto)
            .HasForeignKey<FotoPublicacion>(x => x.PublicacionMascotaId).OnDelete(DeleteBehavior.Cascade);
        b.HasIndex(x => x.PublicacionMascotaId).IsUnique();
    }
}
