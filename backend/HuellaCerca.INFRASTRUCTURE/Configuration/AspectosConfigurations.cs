using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class AspectoRecomendacionConfiguration : IEntityTypeConfiguration<AspectoRecomendacion>
{
    public void Configure(EntityTypeBuilder<AspectoRecomendacion> b)
    {
        b.ToTable("aspectos_recomendacion");
        b.HasKey(x => x.Id);
        b.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
        b.HasIndex(x => x.Nombre).IsUnique();
        var nombres = new[] { "Buena atención", "Responsabilidad", "Cumplimiento", "Buen trato con la mascota", "Rapidez", "Buena comunicación" };
        b.HasData(nombres.Select((n, i) => new AspectoRecomendacion {
            Id = Guid.Parse($"20000000-0000-0000-0000-{i + 1:000000000000}"), Nombre = n, Activo = true }));
    }
}

public sealed class RecomendacionAspectoConfiguration : IEntityTypeConfiguration<RecomendacionAspecto>
{
    public void Configure(EntityTypeBuilder<RecomendacionAspecto> b)
    {
        b.ToTable("recomendaciones_aspectos");
        b.HasKey(x => new { x.RecomendacionId, x.AspectoRecomendacionId });
        b.HasOne(x => x.Recomendacion).WithMany(x => x.Aspectos).HasForeignKey(x => x.RecomendacionId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.AspectoRecomendacion).WithMany().HasForeignKey(x => x.AspectoRecomendacionId).OnDelete(DeleteBehavior.Restrict);
    }
}
