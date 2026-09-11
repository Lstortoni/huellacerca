using HuellaCerca.GeoRefImporter;
using HuellaCerca.INFRASTRUCTURE.Data;
using Microsoft.EntityFrameworkCore;

using var cancellation = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => { e.Cancel = true; cancellation.Cancel(); };
try
{
    var connection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
        ?? throw new InvalidOperationException("Falta ConnectionStrings__DefaultConnection.");
    await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options);
    if (args is ["--migrate-only"])
    {
        await db.Database.MigrateAsync(cancellation.Token);
        Console.WriteLine("Migraciones aplicadas.");
        return 0;
    }
    if (args.Length > 0) throw new ArgumentException("Única opción admitida: --migrate-only.");
    if ((await db.Database.GetPendingMigrationsAsync(cancellation.Token)).Any())
        throw new InvalidOperationException("Hay migraciones pendientes. Ejecutar primero el servicio de migraciones.");
    using var http = new HttpClient { BaseAddress = new Uri("https://apis.datos.gob.ar/georef/api/"), Timeout = TimeSpan.FromSeconds(90) };
    var importer = new GeorefImporter(http, db);
    await importer.ImportAsync(cancellation.Token);
    return 0;
}
catch (OperationCanceledException)
{
    Console.Error.WriteLine("Importación cancelada.");
    return 1;
}
catch (Exception ex)
{
    // No imprimir la cadena de conexión ni datos de credenciales.
    Console.Error.WriteLine($"La operación falló ({ex.GetType().Name}): {ex.Message}");
    return 1;
}

