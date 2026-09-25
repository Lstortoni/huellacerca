using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.CONTRACT.Ubicacion;

namespace HuellaCerca.INTERFACES.Services;

public interface IPublicacionService
{
    IReadOnlyList<CaracteristicaMascotaDto> Caracteristicas(int tipoMascota);
    Task<PaginaDto<CoincidenciaPublicacionDto>> CoincidenciasAsync(Guid id, Guid mascoteroId, CoincidenciasQuery query, CancellationToken ct);
    Task<PublicacionDto> CrearAsync(Guid mascoteroId, CrearPublicacionRequest request, CancellationToken ct);
    Task<PublicacionDto> EditarAsync(Guid id, Guid mascoteroId, EditarPublicacionRequest request, CancellationToken ct);
    Task<PublicacionDto> PorIdAsync(Guid id, CancellationToken ct);
    Task<PaginaDto<PublicacionDto>> BuscarAsync(PublicacionesQuery query, CancellationToken ct);
    Task<PublicacionDto> ResolverAsync(Guid id, Guid mascoteroId, CancellationToken ct);
    Task<PublicacionDto> ReabrirAsync(Guid id, Guid mascoteroId, CancellationToken ct);
}
