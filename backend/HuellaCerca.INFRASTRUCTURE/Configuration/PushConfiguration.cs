using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class DispositivoPushConfiguration : IEntityTypeConfiguration<DispositivoPush>
{
    public void Configure(EntityTypeBuilder<DispositivoPush> b)
    {
        b.ToTable("DispositivosPush");
        b.HasKey(x => x.Id);
        b.Property(x => x.Token).HasMaxLength(2048).IsRequired();
        b.Property(x => x.Plataforma).HasMaxLength(10).IsRequired();
        b.HasIndex(x => x.Token).IsUnique().HasFilter("\"Activo\" = TRUE");
        b.HasIndex(x => new { x.MascoteroId, x.Activo });
        b.HasOne<Mascotero>().WithMany().HasForeignKey(x => x.MascoteroId).OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class EnvioPushConfiguration : IEntityTypeConfiguration<EnvioPush>
{
    public void Configure(EntityTypeBuilder<EnvioPush> b)
    {
        b.ToTable("EnviosPush");
        b.HasKey(x => x.Id);
        b.Property(x => x.Resultado).HasMaxLength(40);
        b.HasIndex(x => new { x.NotificacionId, x.DispositivoPushId }).IsUnique();
        b.HasIndex(x => x.ProximoIntento).HasFilter("\"FechaFinalizacion\" IS NULL");
        b.HasOne<Notificacion>().WithMany().HasForeignKey(x => x.NotificacionId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<DispositivoPush>().WithMany().HasForeignKey(x => x.DispositivoPushId).OnDelete(DeleteBehavior.Cascade);
    }
}
