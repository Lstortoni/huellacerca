using HuellaCerca.CONTRACT.Recomendaciones;
using HuellaCerca.MODEL;
namespace HuellaCerca.INTERFACES.Repositories;

public interface IRecomendacionRepository
{
    Task<IReadOnlyList<Rubro>> RubrosAsync(CancellationToken ct);
    Task<bool> RubroActivoAsync(Guid id, CancellationToken ct);
    Task<PrestadorServicio?> PrestadorAsync(Guid id, CancellationToken ct);
    Task<IReadOnlyList<PrestadorServicio>> SimilaresAsync(SimilaresQuery query, CancellationToken ct);
    Task<Recomendacion?> PorIdAsync(Guid id, CancellationToken ct);
    Task<(IReadOnlyList<Recomendacion> Items, int Total)> BuscarAsync(RecomendacionesQuery query, CancellationToken ct);
    void Agregar(Recomendacion recomendacion);
    void Eliminar(Recomendacion recomendacion);
    Task GuardarAsync(CancellationToken ct);
}

