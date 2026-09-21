using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;
public sealed class FotoPendienteConfiguration : IEntityTypeConfiguration<FotoPendienteLimpieza>
{
    public void Configure(EntityTypeBuilder<FotoPendienteLimpieza> b)
    {
        b.ToTable("fotos_pendientes_limpieza");
        b.HasKey(x => x.ObjectKey);
        b.Property(x => x.ObjectKey).HasMaxLength(500);
        b.HasIndex(x => x.LimpiarDesdeUtc);
    }
}
