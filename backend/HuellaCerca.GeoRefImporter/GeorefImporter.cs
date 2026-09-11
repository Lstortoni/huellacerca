using System.Net;
using System.Text.Json;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.MODEL;
using Microsoft.EntityFrameworkCore;

namespace HuellaCerca.GeoRefImporter;

public sealed class GeorefImporter(HttpClient http, AppDbContext db)
{
    public async Task ImportAsync(CancellationToken ct)
    {
        Console.WriteLine("Descargando provincias y localidades censales de GeoRef...");
        // Primero descargar y validar TODO. Ningún cambio en la base si falla GeoRef.
        var provincias = await DownloadAsync("provincias", "provincias", ct);
        var localidades = await DownloadAsync("localidades-censales", "localidades_censales", ct);
        var provinceIds = provincias.Select(x => Required(x, "id")).ToHashSet();
        foreach (var item in provincias) _ = Required(item, "nombre");
        foreach (var item in localidades)
        {
            _ = Required(item, "nombre");
            if (!provinceIds.Contains(Required(item.GetProperty("provincia"), "id")))
                throw new InvalidDataException("GeoRef devolvió una localidad con provincia desconocida.");
        }

        await using var tx = await db.Database.BeginTransactionAsync(ct);
        // Serializa importaciones simultáneas; el bloqueo se libera al terminar la transacción.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(48203117)", ct);
        var pais = await db.Paises.SingleOrDefaultAsync(x => x.Codigo == "AR", ct);
        if (pais is null) { pais = new Pais { Codigo = "AR" }; db.Paises.Add(pais); }
        pais.Nombre = "Argentina";
        pais.Activo = true;
        var existentes = await db.Provincias.ToDictionaryAsync(x => x.GeorefId, ct);
        foreach (var item in provincias)
        {
            var id = Required(item, "id");
            if (!existentes.TryGetValue(id, out var provincia))
            {
                provincia = new Provincia { GeorefId = id, PaisCodigo = "AR" };
                db.Provincias.Add(provincia);
                existentes.Add(id, provincia);
            }
            provincia.Nombre = Required(item, "nombre");
            provincia.Activa = true;
        }
        var localidadesExistentes = await db.Localidades.ToDictionaryAsync(x => x.GeorefId, ct);
        foreach (var item in localidades)
        {
            var id = Required(item, "id");
            if (!localidadesExistentes.TryGetValue(id, out var localidad))
            {
                localidad = new Localidad { GeorefId = id };
                db.Localidades.Add(localidad);
                localidadesExistentes.Add(id, localidad);
            }
            localidad.Nombre = Required(item, "nombre");
            localidad.NombreBusqueda = TextoBusqueda.Normalizar(localidad.Nombre);
            localidad.ProvinciaId = existentes[Required(item.GetProperty("provincia"), "id")].Id;
            localidad.Activa = true;
            if (item.TryGetProperty("centroide", out var centroide) && centroide.ValueKind == JsonValueKind.Object)
            {
                localidad.Latitud = Coordinate(centroide, "lat");
                localidad.Longitud = Coordinate(centroide, "lon");
            }
        }
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        Console.WriteLine($"Importación completa: {provincias.Count} provincias, {localidades.Count} localidades censales. IDs locales conservados; registros ausentes en origen no se eliminan.");
    }

    private async Task<List<JsonElement>> DownloadAsync(string resource, string property, CancellationToken ct)
    {
        var items = new List<JsonElement>();
        var ids = new HashSet<string>();
        int? expected = null;
        do
        {
            using var doc = await GetPageAsync($"{resource}?max=1000&inicio={items.Count}&orden=id", ct);
            var root = doc.RootElement;
            var total = root.GetProperty("total").GetInt32();
            if (total <= 0 || (expected.HasValue && total != expected.Value))
                throw new InvalidDataException("Catálogo vacío o modificado durante la descarga. Reintentar.");
            expected = total;
            if (root.GetProperty("inicio").GetInt32() != items.Count)
                throw new InvalidDataException("GeoRef devolvió una página fuera de secuencia.");
            var page = root.GetProperty(property).EnumerateArray().ToArray();
            if (page.Length == 0) throw new InvalidDataException("Página vacía antes de completar el catálogo.");
            foreach (var item in page)
            {
                if (!ids.Add(Required(item, "id"))) throw new InvalidDataException("Identificador repetido en GeoRef.");
                items.Add(item.Clone());
            }
            Console.WriteLine($"{resource}: {items.Count}/{expected}");
        } while (items.Count < expected);
        if (items.Count != expected) throw new InvalidDataException("El total de GeoRef no coincide con los registros descargados.");
        return items;
    }

    private async Task<JsonDocument> GetPageAsync(string url, CancellationToken ct)
    {
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                using var response = await http.GetAsync(url, ct);
                response.EnsureSuccessStatusCode();
                await using var stream = await response.Content.ReadAsStreamAsync(ct);
                return await JsonDocument.ParseAsync(stream, cancellationToken: ct);
            }
            catch (HttpRequestException ex) when (attempt < 3 &&
                (ex.StatusCode is null || ex.StatusCode == HttpStatusCode.TooManyRequests || (int)ex.StatusCode.Value >= 500))
            {
                Console.WriteLine($"Fallo transitorio de GeoRef. Reintento {attempt}/2.");
                await Task.Delay(TimeSpan.FromSeconds(attempt * 2), ct);
            }
            catch (OperationCanceledException) when (!ct.IsCancellationRequested && attempt < 3)
            {
                await Task.Delay(TimeSpan.FromSeconds(attempt * 2), ct);
            }
        }
    }

    private static string Required(JsonElement item, string property) =>
        item.GetProperty(property).GetString() is { Length: > 0 } value ? value
            : throw new InvalidDataException($"Campo obligatorio vacío: {property}.");
    private static decimal? Coordinate(JsonElement item, string property) =>
        item.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.Number
            && value.TryGetDecimal(out var number) ? number : null;
}

