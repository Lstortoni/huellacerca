using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.CONTRACT.Ubicacion;

namespace HuellaCerca.INTERFACES.Services;

public interface IPublicacionService
{
    Task<PublicacionDto> CrearAsync(Guid mascoteroId, CrearPublicacionRequest request, CancellationToken ct);
    Task<PublicacionDto> PorIdAsync(Guid id, CancellationToken ct);
    Task<PaginaDto<PublicacionDto>> BuscarAsync(PublicacionesQuery query, CancellationToken ct);
    Task<PublicacionDto> ResolverAsync(Guid id, Guid mascoteroId, CancellationToken ct);
}
