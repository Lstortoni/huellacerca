using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;

namespace HuellaCerca.SERVICES;

public sealed class FotoService(IFotoRepository repository, IAlmacenamientoFotos storage, IProcesadorFoto procesador) : IFotoService
{
    public async Task<FotoPublicacionDto> SubirAsync(Guid id, Guid autor, Stream contenido, CancellationToken ct)
    {
        var p = await ObtenerAsync(id, ct);
        Autor(p, autor);
        if (!storage.Habilitado) throw new AppException(503, "La carga de fotos todavía no está configurada.");
        var bytes = await procesador.OptimizarAsync(contenido, ct);
        var foto = new FotoPublicacion { PublicacionMascotaId = id, ObjectKey = $"mascotas/{id}/{Guid.NewGuid():N}.webp" };
        // Se registra ANTES de subir. Si falla R2 o el commit, la limpieza recupera el objeto huérfano.
        await repository.PrepararAsync(foto.ObjectKey, ct);
        await storage.SubirAsync(foto.ObjectKey, bytes, ct);
        await repository.ConfirmarAsync(id, p.Foto?.Id, foto, ct);
        return new(foto.Id, $"api/publicaciones/{id}/foto?v={foto.Id}");
    }

    public async Task<byte[]> LeerAsync(Guid id, CancellationToken ct)
    {
        var p = await ObtenerAsync(id, ct);
        if (p.Foto is null) throw new AppException(404, "El aviso no tiene foto.");
        return await storage.LeerAsync(p.Foto.ObjectKey, ct);
    }

    public async Task EliminarAsync(Guid id, Guid autor, CancellationToken ct)
    {
        var p = await ObtenerAsync(id, ct);
        Autor(p, autor);
        if (p.Foto is not null) await repository.ConfirmarAsync(id, p.Foto.Id, null, ct);
    }

    public async Task LimpiarAsync(CancellationToken ct)
    {
        if (!storage.Habilitado) return;
        foreach (var key in await repository.PendientesAsync(ct))
        {
            await storage.EliminarAsync(key, ct);
            await repository.CompletarLimpiezaAsync(key, ct);
        }
    }

    private async Task<PublicacionMascota> ObtenerAsync(Guid id, CancellationToken ct) =>
        await repository.ObtenerAsync(id, ct) ?? throw new AppException(404, "Publicación no encontrada.");
    private static void Autor(PublicacionMascota p, Guid autor)
    {
        if (p.MascoteroId != autor) throw new AppException(403, "Solo el autor puede modificar la foto.");
    }
}
