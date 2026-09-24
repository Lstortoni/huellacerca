using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HuellaCerca.INFRASTRUCTURE.Configuration;

public sealed class NotificacionConfiguration : IEntityTypeConfiguration<Notificacion>
{
    public void Configure(EntityTypeBuilder<Notificacion> b)
    {
        b.ToTable("Notificaciones");
        b.HasKey(x => x.Id);
        b.Property(x => x.Titulo).HasMaxLength(150).IsRequired();
        b.Property(x => x.Mensaje).HasMaxLength(500).IsRequired();
        b.HasOne<Mascotero>().WithMany().HasForeignKey(x => x.MascoteroId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<PublicacionMascota>().WithMany().HasForeignKey(x => x.PublicacionId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<PublicacionMascota>().WithMany().HasForeignKey(x => x.PublicacionCoincidenteId).OnDelete(DeleteBehavior.Cascade);
        b.HasIndex(x => new { x.MascoteroId, x.PublicacionId, x.PublicacionCoincidenteId }).IsUnique();
        b.HasIndex(x => new { x.MascoteroId, x.FechaCreacion, x.Id });
        b.HasIndex(x => x.MascoteroId).HasFilter("\"FechaLectura\" IS NULL");
    }
}

public sealed class NotificacionPendienteConfiguration : IEntityTypeConfiguration<NotificacionPendiente>
{
    public void Configure(EntityTypeBuilder<NotificacionPendiente> b)
    {
        b.ToTable("NotificacionesPendientes");
        b.HasKey(x => x.PublicacionId);
        b.HasOne<PublicacionMascota>().WithMany().HasForeignKey(x => x.PublicacionId).OnDelete(DeleteBehavior.Cascade);
        b.HasIndex(x => x.FechaCreacion);
    }
}
