using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.CONTRACT.Ubicacion;
namespace HuellaCerca.INTERFACES.Services;
public interface IRecomendacionService
{
    Task<IReadOnlyList<RubroDto>> RubrosAsync(CancellationToken ct);
    Task<IReadOnlyList<AspectoDto>> AspectosAsync(CancellationToken ct);
    Task<IReadOnlyList<PrestadorDto>> SimilaresAsync(SimilaresQuery query, CancellationToken ct);
    Task<PrestadorDto> PrestadorAsync(Guid id, CancellationToken ct);
    Task<PaginaDto<MascoteroRecomiendaDto>> RecomendadoresAsync(Guid prestadorId, RecomendadoresQuery query, CancellationToken ct);
    Task<PaginaDto<PrestadorDto>> BuscarPrestadoresAsync(RecomendacionesQuery query, CancellationToken ct);
    Task<(RecomendacionDto Item, bool Creada)> CrearAsync(Guid mascoteroId, CrearRecomendacionRequest request, CancellationToken ct);
    Task<RecomendacionDto> PorIdAsync(Guid id, Guid mascoteroId, CancellationToken ct);
    Task<PaginaDto<RecomendacionDto>> MiasAsync(Guid mascoteroId, RecomendacionesQuery query, CancellationToken ct);
    Task<RecomendacionDto> EditarAsync(Guid id, Guid mascoteroId, EditarRecomendacionRequest request, CancellationToken ct);
    Task EliminarAsync(Guid id, Guid mascoteroId, CancellationToken ct);
}
