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
            t.HasCheckConstraint("CK_publicaciones_mascotas_tipo", "\"TipoPublicacion\" IN (1, 2)");
            t.HasCheckConstraint("CK_publicaciones_mascotas_mascota", "\"TipoMascota\" IN (1, 2, 3)");
            t.HasCheckConstraint("CK_publicaciones_mascotas_estado", "\"Estado\" IN (1, 2)");
        });
        b.HasKey(x => x.Id);
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
        b.ToTable("fotos_publicaciones", t =>
            t.HasCheckConstraint("CK_fotos_publicaciones_orden", "\"Orden\" >= 0"));
        b.HasKey(x => x.Id);
        b.Property(x => x.RutaArchivo).HasMaxLength(500).IsRequired();
        b.HasOne(x => x.PublicacionMascota).WithMany(x => x.Fotografias)
            .HasForeignKey(x => x.PublicacionMascotaId).OnDelete(DeleteBehavior.Cascade);
        b.HasIndex(x => new { x.PublicacionMascotaId, x.Orden }).IsUnique();
    }
}

