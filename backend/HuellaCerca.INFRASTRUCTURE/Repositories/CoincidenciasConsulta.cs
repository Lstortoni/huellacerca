using HuellaCerca.MODEL;

namespace HuellaCerca.INFRASTRUCTURE.Repositories;

/// Una misma selección para el listado y la generación de notificaciones.
internal static class CoincidenciasConsulta
{
    public static IQueryable<PublicacionMascota> Aplicar(IQueryable<PublicacionMascota> publicaciones, PublicacionMascota origen)
    {
        var opuesto = origen.TipoPublicacion switch
        {
            TipoPublicacionMascota.Perdida => TipoPublicacionMascota.Encontrada,
            TipoPublicacionMascota.Encontrada => TipoPublicacionMascota.Perdida,
            TipoPublicacionMascota.Adopcion => TipoPublicacionMascota.BuscoAdoptar,
            TipoPublicacionMascota.BuscoAdoptar => TipoPublicacionMascota.Adopcion,
            _ => (TipoPublicacionMascota)0
        };
        DateOnly? desde = null, hasta = null;
        if (origen.TipoPublicacion is TipoPublicacionMascota.Perdida or TipoPublicacionMascota.Encontrada)
        {
            if (origen.FechaSuceso is not DateOnly fecha) return publicaciones.Where(x => false);
            DateOnly Mover(int dias) => DateOnly.FromDayNumber(Math.Clamp(fecha.DayNumber + dias,
                DateOnly.MinValue.DayNumber, DateOnly.MaxValue.DayNumber));
            var perdida = origen.TipoPublicacion == TipoPublicacionMascota.Perdida;
            desde = Mover(perdida ? -3 : -30);
            hasta = Mover(perdida ? 30 : 3);
        }
        return publicaciones.Where(x => origen.Estado == EstadoPublicacionMascota.Activa
            && x.Id != origen.Id && x.Estado == EstadoPublicacionMascota.Activa
            && x.TipoPublicacion == opuesto && x.TipoMascota == origen.TipoMascota
            && x.LocalidadId == origen.LocalidadId
            && (!desde.HasValue || x.FechaSuceso >= desde) && (!hasta.HasValue || x.FechaSuceso <= hasta)
            && ((origen.Tamano.HasValue && x.Tamano == origen.Tamano)
                || (origen.Raza.HasValue && x.Raza == origen.Raza)
                || (origen.Pelaje.HasValue && x.Pelaje == origen.Pelaje)
                || (origen.ColorPredominante.HasValue && x.ColorPredominante == origen.ColorPredominante)
                || (origen.ColorOjos.HasValue && x.ColorOjos == origen.ColorOjos)));
    }
}
