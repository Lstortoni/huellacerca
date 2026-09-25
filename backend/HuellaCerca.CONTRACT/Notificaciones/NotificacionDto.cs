using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Notificaciones;

/// Publicacion y Coincidente resumen ambos avisos con su estado actual, para
/// mostrar la notificación sin pedir cada detalle. Los IDs se conservan por compatibilidad.
public sealed record NotificacionDto(Guid Id, Guid PublicacionId, Guid PublicacionCoincidenteId,
    string Titulo, string Mensaje, DateTime FechaCreacion, DateTime? FechaLectura,
    PublicacionResumenDto Publicacion, PublicacionResumenDto Coincidente);

/// FotoUrl es relativa a la API, igual que en PublicacionDto; null si no tiene foto.
public sealed record PublicacionResumenDto(Guid Id, int TipoPublicacion, int TipoMascota,
    string? NombreMascota, string Localidad, int Estado, string? FotoUrl);

public sealed class NotificacionesQuery
{
    [Range(1, 1000000)] public int Pagina { get; set; } = 1;
    [Range(1, 50)] public int TamanoPagina { get; set; } = 20;
    public bool SoloNoLeidas { get; set; }
}
