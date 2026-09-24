using System.ComponentModel.DataAnnotations;

namespace HuellaCerca.CONTRACT.Notificaciones;

public sealed record NotificacionDto(Guid Id, Guid PublicacionId, Guid PublicacionCoincidenteId,
    string Titulo, string Mensaje, DateTime FechaCreacion, DateTime? FechaLectura);

public sealed class NotificacionesQuery
{
    [Range(1, 1000000)] public int Pagina { get; set; } = 1;
    [Range(1, 50)] public int TamanoPagina { get; set; } = 20;
    public bool SoloNoLeidas { get; set; }
}
