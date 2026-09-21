using ImageMagick;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.INFRASTRUCTURE.Storage;

public sealed class ProcesadorFoto : IProcesadorFoto
{
    private static readonly SemaphoreSlim Slots = new(2);
    static ProcesadorFoto()
    {
        ResourceLimits.Memory = 256 * 1024 * 1024;
        ResourceLimits.Disk = 0;
        ResourceLimits.Thread = 2;
    }
    public async Task<byte[]> OptimizarAsync(Stream entrada, CancellationToken ct)
    {
        await Slots.WaitAsync(ct);
        try { return await ProcesarAsync(entrada, ct); }
        finally { Slots.Release(); }
    }
    private static async Task<byte[]> ProcesarAsync(Stream entrada, CancellationToken ct)
    {
        using var buffer = new MemoryStream();
        var chunk = new byte[81920];
        int leidos;
        while ((leidos = await entrada.ReadAsync(chunk, ct)) > 0)
        {
            if (buffer.Length + leidos > 10 * 1024 * 1024) throw new AppException(413, "La foto no puede superar 10 MB.");
            buffer.Write(chunk, 0, leidos);
        }
        var bytes = buffer.ToArray();
        // Solo decodificadores raster permitidos; nunca interpretar SVG, PDF o nombres de archivo.
        MagickFormat formato = bytes.Length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255 ? MagickFormat.Jpeg
            : bytes.Length >= 8 && bytes.AsSpan(0, 8).SequenceEqual(new byte[] {137,80,78,71,13,10,26,10}) ? MagickFormat.Png
            : bytes.Length >= 12 && System.Text.Encoding.ASCII.GetString(bytes, 0, 4) == "RIFF" && System.Text.Encoding.ASCII.GetString(bytes, 8, 4) == "WEBP" ? MagickFormat.WebP
            : throw new AppException(400, "Seleccioná una imagen JPEG, PNG o WebP.");
        try
        {
            var read = new MagickReadSettings { Format = formato, FrameCount = 1 };
            using var image = new MagickImage();
            image.Ping(bytes, read);
            if ((ulong)image.Width * image.Height > 40_000_000 || image.Width == 0 || image.Height == 0)
                throw new AppException(400, "La imagen tiene dimensiones demasiado grandes.");
            ct.ThrowIfCancellationRequested();
            image.Read(bytes, read);
            image.AutoOrient();
            image.Resize(new MagickGeometry(1280, 1280) { Greater = true });
            image.Strip();
            image.Format = MagickFormat.WebP;
            byte[] result = [];
            // Un único archivo, máximo 250 KiB; bajar calidad y luego dimensiones si es necesario.
            foreach (var size in new uint[] {1280, 1024, 800, 640})
            {
                image.Resize(new MagickGeometry(size, size) { Greater = true });
                foreach (var quality in new uint[] {75, 65, 55})
                {
                    ct.ThrowIfCancellationRequested();
                    image.Quality = quality;
                    result = image.ToByteArray();
                    if (result.Length <= 250 * 1024) return result;
                }
            }
            throw new AppException(400, "No pudimos reducir esta foto. Probá con otra imagen.");
        }
        catch (MagickException) { throw new AppException(400, "La imagen está dañada o no se puede interpretar."); }
    }
}
