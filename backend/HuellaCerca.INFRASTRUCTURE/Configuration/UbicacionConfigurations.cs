using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class PaisConfiguration : IEntityTypeConfiguration<Pais>
{
    public void Configure(EntityTypeBuilder<Pais> b)
    {
        b.ToTable("paises");
        b.HasKey(x => x.Codigo);
        b.Property(x => x.Codigo).HasMaxLength(2);
        b.Property(x => x.Nombre).HasMaxLength(150).IsRequired();
    }
}
public sealed class ProvinciaConfiguration : IEntityTypeConfiguration<Provincia>
{
    public void Configure(EntityTypeBuilder<Provincia> b)
    {
        b.ToTable("provincias");
        b.HasKey(x => x.Id);
        b.Property(x => x.GeorefId).HasMaxLength(20).IsRequired();
        b.HasIndex(x => x.GeorefId).IsUnique();
        b.Property(x => x.Nombre).HasMaxLength(150).IsRequired();
        b.Property(x => x.PaisCodigo).HasMaxLength(2).IsRequired();
        b.HasOne(x => x.Pais).WithMany(x => x.Provincias).HasForeignKey(x => x.PaisCodigo).OnDelete(DeleteBehavior.Restrict);
    }
}
public sealed class LocalidadConfiguration : IEntityTypeConfiguration<Localidad>
{
    public void Configure(EntityTypeBuilder<Localidad> b)
    {
        b.ToTable("localidades");
        b.HasKey(x => x.Id);
        b.Property(x => x.GeorefId).HasMaxLength(30).IsRequired();
        b.HasIndex(x => x.GeorefId).IsUnique();
        b.Property(x => x.Nombre).HasMaxLength(200).IsRequired();
        b.Property(x => x.NombreBusqueda).HasMaxLength(200).IsRequired();
        b.Property(x => x.Latitud).HasPrecision(10, 7);
        b.Property(x => x.Longitud).HasPrecision(10, 7);
        b.HasIndex(x => new { x.ProvinciaId, x.NombreBusqueda });
        b.HasOne(x => x.Provincia).WithMany(x => x.Localidades).HasForeignKey(x => x.ProvinciaId).OnDelete(DeleteBehavior.Restrict);
    }
}

