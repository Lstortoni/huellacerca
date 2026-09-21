using HuellaCerca.CONTRACT.Publicaciones;

namespace HuellaCerca.INTERFACES.Services;

public interface IFotoService
{
    Task<FotoPublicacionDto> SubirAsync(Guid id, Guid autor, Stream contenido, CancellationToken ct);
    Task<byte[]> LeerAsync(Guid id, CancellationToken ct);
    Task EliminarAsync(Guid id, Guid autor, CancellationToken ct);
    Task LimpiarAsync(CancellationToken ct);
}

public interface IAlmacenamientoFotos
{
    bool Habilitado { get; }
    Task SubirAsync(string key, byte[] contenido, CancellationToken ct);
    Task<byte[]> LeerAsync(string key, CancellationToken ct);
    Task EliminarAsync(string key, CancellationToken ct);
}

public interface IProcesadorFoto
{
    Task<byte[]> OptimizarAsync(Stream entrada, CancellationToken ct);
}
