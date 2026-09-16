using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.MODEL;

namespace HuellaCerca.INTERFACES.Repositories;

public interface IPublicacionRepository
{
    void Agregar(PublicacionMascota publicacion);
    Task<PublicacionMascota?> PorIdAsync(Guid id, CancellationToken ct);
    Task<(IReadOnlyList<PublicacionMascota> Items, int Total)> BuscarAsync(PublicacionesQuery query, CancellationToken ct);
    Task GuardarAsync(CancellationToken ct);
}
