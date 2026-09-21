using System.Net.Http.Json;
using System.Text.Json;
using ImageMagick;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INFRASTRUCTURE.Repositories;
using HuellaCerca.INFRASTRUCTURE.Storage;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;
using HuellaCerca.SERVICES;
using Microsoft.EntityFrameworkCore;

var ct = CancellationToken.None;
var connection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")!;
var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options;
using var http = new HttpClient { BaseAddress = new Uri("http://huellacerca_api:8080") };
var tag = "hc-photo-test-" + Guid.NewGuid().ToString("N");
var provinces = await http.GetFromJsonAsync<JsonElement>("api/provincias");
var locations = await http.GetFromJsonAsync<JsonElement>($"api/localidades?provinciaId={provinces[0].GetProperty("id").GetString()}");
var locality = locations.GetProperty("items")[0].GetProperty("id").GetGuid();
var registration = await http.PostAsJsonAsync("api/auth/register", new {
    nombre = "Prueba", apellido = "Fotos", email = tag + "@example.invalid", password = "Prueba.Local-2026!",
    passwordConfirm = "Prueba.Local-2026!", localidadId = locality });
registration.EnsureSuccessStatusCode();
var session = await registration.Content.ReadFromJsonAsync<JsonElement>();
http.DefaultRequestHeaders.Authorization = new("Bearer", session.GetProperty("accessToken").GetString());
var owner = session.GetProperty("usuario").GetProperty("mascotero").GetProperty("id").GetGuid();
var response = await http.PostAsJsonAsync("api/publicaciones", new { tipoPublicacion = 3, tipoMascota = 1,
    descripcion = tag, localidadId = locality, zona = "Prueba", informacionContacto = "Prueba", tamano = 1 });
response.EnsureSuccessStatusCode();
var json = await response.Content.ReadFromJsonAsync<JsonElement>();
var id = json.GetProperty("id").GetGuid();
var storage = new MemoryStorage();
var processor = new ProcesadorFoto();
using var source = new MagickImage(MagickColors.SaddleBrown, 2000, 1500);
source.SetAttribute("comment", "metadata privada");
var png = source.ToByteArray(MagickFormat.Png);
var optimized = await processor.OptimizarAsync(new MemoryStream(png), ct);
using (var image = new MagickImage(optimized))
{
    Check(image.Format == MagickFormat.WebP && image.Width <= 1280 && image.Height <= 1280, "Formato y dimensiones");
    Check(optimized.Length <= 250 * 1024 && !image.ProfileNames.Any() && image.GetAttribute("comment") is null, "Peso/metadatos");
}
await Error(400, () => processor.OptimizarAsync(new MemoryStream("<svg/>"u8.ToArray()), ct));
await Error(413, () => processor.OptimizarAsync(new MemoryStream(new byte[10 * 1024 * 1024 + 1]), ct));
Console.WriteLine("OK: PNG → WebP, 1280 px, <=250 KiB, sin metadatos; rechazo de SVG y exceso de tamaño.");

async Task<T> Run<T>(Func<FotoService, Task<T>> run)
{
    await using var db = new AppDbContext(options);
    return await run(new FotoService(new FotoRepository(db), storage, processor));
}
async Task Clean()
{
    await using var db = new AppDbContext(options);
    var keys = storage.Keys.ToArray();
    await db.Set<FotoPendienteLimpieza>().Where(x => keys.Contains(x.ObjectKey))
        .ExecuteUpdateAsync(s => s.SetProperty(x => x.LimpiarDesdeUtc, DateTime.UtcNow.AddMinutes(-1)));
    await new FotoService(new FotoRepository(db), storage, processor).LimpiarAsync(ct);
}
try
{
    await Error(403, () => Run(s => s.SubirAsync(id, Guid.NewGuid(), new MemoryStream(png), ct)));
    await Error(404, () => Run(s => s.LeerAsync(id, ct)));
    var first = await Run(s => s.SubirAsync(id, owner, new MemoryStream(png), ct));
    Check((await Run(s => s.LeerAsync(id, ct))).Length == optimized.Length, "Lectura");
    var second = await Run(s => s.SubirAsync(id, owner, new MemoryStream(png), ct));
    Check(first.Id != second.Id && first.Url != second.Url, "Reemplazo versionado");
    await Clean();
    Check(storage.Count == 1, "Limpieza del reemplazo");
    storage.FailUpload = true;
    await Error(503, () => Run(s => s.SubirAsync(id, owner, new MemoryStream(png), ct)));
    storage.FailUpload = false;
    await Clean();
    Check(storage.Count == 1, "Limpieza tras subida interrumpida conserva foto anterior");
    await using (var db = new AppDbContext(options))
    {
        Check(await db.FotosPublicaciones.CountAsync(x => x.PublicacionMascotaId == id) == 1, "Una foto en DB");
        Check((await db.FotosPublicaciones.SingleAsync(x => x.PublicacionMascotaId == id)).Id == second.Id, "Fallo no modifica foto");
    }
    storage.Barrier = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
    async Task<int> Upload()
    {
        try { await Run(s => s.SubirAsync(id, owner, new MemoryStream(png), ct)); return 200; }
        catch (AppException e) { return e.StatusCode; }
    }
    var concurrent = await Task.WhenAll(Upload(), Upload());
    storage.Barrier = null;
    Check(concurrent.Order().SequenceEqual(new[] {200,409}), "Reemplazo concurrente no pierde cambios");
    await Clean();
    Check(storage.Count == 1, "Sin archivos huérfanos tras concurrencia");
    await Run(async s => { await s.EliminarAsync(id, owner, ct); return true; });
    await Clean();
    Check(storage.Count == 0, "Eliminar foto y archivo");
    await Error(404, () => Run(s => s.LeerAsync(id, ct)));
    Console.WriteLine("OK: permisos, subir/leer/reemplazar/eliminar, concurrencia, fallo remoto y limpieza durable.");
}
finally
{
    await Run(async s => { await s.EliminarAsync(id, owner, ct); return true; });
    await Clean();
    await http.PatchAsync($"api/publicaciones/{id}/resolver", null);
    await http.PostAsJsonAsync("api/auth/logout", new { refreshToken = session.GetProperty("refreshToken").GetString() });
}

static void Check(bool value, string message) { if (!value) throw new Exception(message); }
static async Task Error(int status, Func<Task> action)
{
    try { await action(); }
    catch (AppException e) when (e.StatusCode == status) { return; }
    throw new Exception($"Esperaba {status}");
}
sealed class MemoryStorage : IAlmacenamientoFotos
{
    readonly System.Collections.Concurrent.ConcurrentDictionary<string, byte[]> files = new();
    public bool Habilitado => true;
    public int Count => files.Count;
    public IEnumerable<string> Keys => files.Keys;
    public bool FailUpload;
    public TaskCompletionSource? Barrier;
    int uploads;
    public async Task SubirAsync(string key, byte[] bytes, CancellationToken ct)
    {
        files[key] = bytes;
        if (FailUpload) throw new AppException(503, "Prueba de respuesta perdida");
        if (Barrier is not null)
        {
            if (Interlocked.Increment(ref uploads) == 2) Barrier.TrySetResult();
            await Barrier.Task.WaitAsync(TimeSpan.FromSeconds(30), ct);
        }
    }
    public Task<byte[]> LeerAsync(string key, CancellationToken ct) => Task.FromResult(files[key]);
    public Task EliminarAsync(string key, CancellationToken ct) { files.TryRemove(key, out _); return Task.CompletedTask; }
}
