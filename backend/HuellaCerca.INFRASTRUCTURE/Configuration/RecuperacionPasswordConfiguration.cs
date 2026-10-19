using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class RecuperacionPasswordConfiguration : IEntityTypeConfiguration<RecuperacionPassword>
{
    public void Configure(EntityTypeBuilder<RecuperacionPassword> b)
    {
        b.ToTable("recuperaciones_password");
        b.HasKey(x => x.UsuarioId);
        b.Property(x => x.CodigoHash).HasMaxLength(64).IsRequired();
        b.Property(x => x.PermisoHash).HasMaxLength(64);
        b.HasIndex(x => x.PermisoHash).IsUnique();
        b.HasOne(x => x.Usuario).WithOne().HasForeignKey<RecuperacionPassword>(x => x.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
