namespace HuellaCerca.MODEL;

public sealed class Notificacion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MascoteroId { get; set; }
    public Guid PublicacionId { get; set; }
    public Guid PublicacionCoincidenteId { get; set; }
    public string Titulo { get; set; } = "Nueva posible coincidencia";
    public string Mensaje { get; set; } = "Hay una publicación que podría coincidir con tu aviso.";
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime? FechaLectura { get; set; }
}

/// Se guarda en la misma transacción que el aviso. Se elimina al completar la búsqueda.
public sealed class NotificacionPendiente
{
    public Guid PublicacionId { get; set; }
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
