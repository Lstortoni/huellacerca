namespace HuellaCerca.MODEL;

public sealed class DispositivoPush
{
    // Identificador aleatorio generado una vez por instalación, no por usuario.
    public Guid Id { get; set; }
    public Guid MascoteroId { get; set; }
    public Guid SesionId { get; set; }
    public string Token { get; set; } = "";
    public string Plataforma { get; set; } = "android";
    public bool Activo { get; set; } = true;
    public Guid Version { get; set; } = Guid.NewGuid();
    public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;
}

/// Un envío por notificación y dispositivo. Persiste los reintentos y su resultado.
public sealed class EnvioPush
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid NotificacionId { get; set; }
    public Guid DispositivoPushId { get; set; }
    public Guid VersionDispositivo { get; set; }
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime ProximoIntento { get; set; } = DateTime.UtcNow;
    public int Intentos { get; set; }
    public Guid? Reserva { get; set; }
    public DateTime? FechaFinalizacion { get; set; }
    public string? Resultado { get; set; }
}
