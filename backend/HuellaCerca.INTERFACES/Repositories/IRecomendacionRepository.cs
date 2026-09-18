using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.MODEL;
namespace HuellaCerca.INTERFACES.Repositories;
public interface IRecomendacionRepository
{
    Task<IReadOnlyList<Rubro>> RubrosAsync(CancellationToken ct);
    Task<IReadOnlyList<AspectoRecomendacion>> AspectosAsync(CancellationToken ct);
    Task<bool> RubroActivoAsync(Guid id, CancellationToken ct);
    Task<PrestadorServicio?> PrestadorAsync(Guid id, CancellationToken ct);
    Task<(IReadOnlyList<MascoteroRecomiendaDto> Items, int Total)> RecomendadoresAsync(Guid prestadorId, RecomendadoresQuery query, CancellationToken ct);
    Task<IReadOnlyList<PrestadorDto>> SimilaresAsync(SimilaresQuery query, CancellationToken ct);
    Task<IReadOnlyList<PrestadorDto>> ResumenesAsync(IReadOnlyList<Guid> ids, CancellationToken ct);
    Task<(IReadOnlyList<PrestadorDto> Items, int Total)> BuscarPrestadoresAsync(RecomendacionesQuery query, CancellationToken ct);
    Task<Recomendacion?> PorIdAsync(Guid id, CancellationToken ct);
    Task<(Recomendacion Item, bool Creada)> CrearUnicaAsync(Recomendacion item, CancellationToken ct);
    Task<(IReadOnlyList<Recomendacion> Items, int Total)> MiasAsync(Guid mascoteroId, RecomendacionesQuery query, CancellationToken ct);
    void Eliminar(Recomendacion recomendacion);
    Task GuardarAsync(CancellationToken ct);
}
