using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.CONTRACT.Publicaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INFRASTRUCTURE.Repositories;
using HuellaCerca.INTERFACES;
using HuellaCerca.MODEL;
using HuellaCerca.SERVICES;
using Microsoft.EntityFrameworkCore;
using Npgsql;

// Base desechable: no se crean avisos ni notificaciones de prueba en la base de la app.
var source = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")!;
var database = "hc_notificaciones_test_" + Guid.NewGuid().ToString("N");
await using var admin = new NpgsqlConnection(source);
await admin.OpenAsync();
await using (var command = new NpgsqlCommand($"CREATE DATABASE {database}", admin)) await command.ExecuteNonQueryAsync();
var connection = new NpgsqlConnectionStringBuilder(source) { Database = database }.ConnectionString;
var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options;
AppDbContext Context() => new(options);
var ct = CancellationToken.None;
var localidad = new Localidad { GeorefId = "test", Nombre = "Prueba", NombreBusqueda = "prueba",
    Provincia = new Provincia { GeorefId = "test", Nombre = "Prueba", Pais = new Pais { Codigo = "ZZ", Nombre = "Prueba" } } };
var a = new Mascotero { Nombre = "A", Apellido = "Test", Localidad = localidad };
var b = new Mascotero { Nombre = "B", Apellido = "Test", Localidad = localidad };
PublicacionMascota Aviso(Mascotero autor, int tipo) => new() {
    MascoteroId = autor.Id, LocalidadId = localidad.Id, TipoPublicacion = (TipoPublicacionMascota)tipo,
    TipoMascota = TipoMascota.Perro, Tamano = TamanoMascota.Chico,
    FechaSuceso = tipo <= 2 ? new DateOnly(2026, 1, 15) : null,
    Descripcion = "Aviso de prueba", Zona = "Prueba", InformacionContacto = "Prueba"
};
async Task Drenar()
{
    for (var i = 0; i < 1000; i++)
    {
        await using var db = Context();
        if (!await new NotificacionRepository(db).ProcesarLoteAsync(ct)) return;
    }
    throw new Exception("La cola no termina");
}
void Check(bool value, string text) { if (!value) throw new Exception(text); Console.WriteLine("OK: " + text); }
try
{
    await using (var db = Context())
    {
        await db.Database.MigrateAsync();
        db.Mascoteros.AddRange(a, b);
        await db.SaveChangesAsync();
    }
    var origen = Aviso(a, 1);
    var compatibles = Enumerable.Range(0, 205).Select(_ => Aviso(b, 2)).ToList();
    var propia = Aviso(a, 2);
    var sinAtributo = Aviso(b, 2); sinAtributo.Tamano = null;
    var fechaIncorrecta = Aviso(b, 2); fechaIncorrecta.FechaSuceso = new DateOnly(2026, 3, 1);
    var resuelta = Aviso(b, 2); resuelta.Estado = EstadoPublicacionMascota.Resuelta;
    compatibles[0].Foto = new FotoPublicacion { ObjectKey = "mascotas/prueba.webp" };
    await using (var db = Context())
    {
        // Simula candidatos históricos: no se encolan por sí solos.
        db.PublicacionesMascotas.AddRange(compatibles);
        db.PublicacionesMascotas.AddRange(propia, sinAtributo, fechaIncorrecta, resuelta);
        new PublicacionRepository(db).Agregar(origen);
        await db.SaveChangesAsync();
    }
    // Un lote en un contexto y continuar con otros simula reiniciar el proceso entre lotes.
    await using (var db = Context())
    {
        await new NotificacionRepository(db).ProcesarLoteAsync(ct);
        Check(await db.Notificaciones.CountAsync() == 200, "Primer lote acotado a 100 parejas");
        Check(await db.NotificacionesPendientes.CountAsync() == 1, "Trabajo persistido hasta completar todos los candidatos");
    }
    await Drenar();
    await using (var db = Context())
    {
        Check(await db.Notificaciones.CountAsync() == 410, "205 candidatos, avisos a ambos autores, excluye propias/sin atributo/fecha/resueltas");
        Check(!await db.NotificacionesPendientes.AnyAsync(), "Cola finalizada tras reabrir contextos");
        // Repetición de ambos sentidos de la pareja y competencia de dos procesadores.
        db.NotificacionesPendientes.Add(new() { PublicacionId = origen.Id });
        db.NotificacionesPendientes.Add(new() { PublicacionId = compatibles[0].Id });
        await db.SaveChangesAsync();
    }
    await Task.WhenAll(Drenar(), Drenar());
    await Drenar();
    await using (var db = Context())
    {
        Check(await db.Notificaciones.CountAsync() == 410, "Reintentos e inversa no duplican notificaciones");
        var service = new NotificacionService(new NotificacionRepository(db));
        var page = await service.ListarAsync(a.Id, new() { TamanoPagina = 10 }, ct);
        Check(page.Total == 205 && page.Items.Count == 10 && page.Items.All(x => x.PublicacionId == origen.Id), "Listado paginado propio");
        Check(page.Items.Zip(page.Items.Skip(1)).All(z => z.First.FechaCreacion >= z.Second.FechaCreacion),
            "El resumen conserva el orden por fecha");
        Check(page.Items.All(x => x.Publicacion.Id == origen.Id && x.Publicacion.TipoPublicacion == 1
            && x.Coincidente.Id == x.PublicacionCoincidenteId && x.Coincidente.TipoPublicacion == 2
            && x.Coincidente.TipoMascota == 1 && x.Coincidente.Localidad == "Prueba" && x.Coincidente.Estado == 1),
            "Cada notificación resume el aviso propio y el coincidente");
        var todas = new List<NotificacionDto>();
        for (var pagina = 1; todas.Count < 205; pagina++)
            todas.AddRange((await service.ListarAsync(a.Id, new() { Pagina = pagina, TamanoPagina = 50 }, ct)).Items);
        var conFoto = todas.Single(x => x.PublicacionCoincidenteId == compatibles[0].Id);
        Check(conFoto.Coincidente.FotoUrl == $"api/publicaciones/{compatibles[0].Id}/foto?v={compatibles[0].Foto!.Id}"
            && todas.Count(x => x.Coincidente.FotoUrl != null) == 1, "Ruta de foto versionada solo si el aviso tiene foto");
        await db.PublicacionesMascotas.Where(x => x.Id == compatibles[1].Id)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Estado, EstadoPublicacionMascota.Resuelta));
        todas.Clear();
        for (var pagina = 1; todas.Count < 205; pagina++)
            todas.AddRange((await service.ListarAsync(a.Id, new() { Pagina = pagina, TamanoPagina = 50 }, ct)).Items);
        Check(todas.Single(x => x.PublicacionCoincidenteId == compatibles[1].Id).Coincidente.Estado == 2,
            "El resumen informa el estado actual del aviso");
        var id = page.Items[0].Id;
        try { await service.LeerAsync(b.Id, id, ct); throw new Exception("Permitió leer notificación ajena"); }
        catch (AppException ex) when (ex.StatusCode == 404) { Console.WriteLine("OK: lectura ajena rechazada"); }
        await service.LeerAsync(a.Id, id, ct);
        var first = await db.Notificaciones.AsNoTracking().SingleAsync(x => x.Id == id);
        await service.LeerAsync(a.Id, id, ct);
        Check((await db.Notificaciones.AsNoTracking().SingleAsync(x => x.Id == id)).FechaLectura == first.FechaLectura, "Lectura idempotente");
        Check(await service.ContarAsync(a.Id, ct) == 204, "Contador de no leídas");
        await service.LeerTodasAsync(a.Id, ct);
        Check(await service.ContarAsync(a.Id, ct) == 0 && await service.ContarAsync(b.Id, ct) == 205, "Leer todas no afecta al otro usuario");
        Check((await service.ListarAsync(a.Id, new() { SoloNoLeidas = true }, ct)).Total == 0, "Filtro de no leídas");
        try { await service.ListarAsync(a.Id, new() { Pagina = 0 }, ct); throw new Exception("Aceptó página cero"); }
        catch (AppException ex) when (ex.StatusCode == 400) { Console.WriteLine("OK: validación de paginación"); }
    }
    var adopcion = Aviso(a, 3);
    var busca = Aviso(b, 4);
    await using (var db = Context())
    {
        var repo = new PublicacionRepository(db);
        repo.Agregar(adopcion); repo.Agregar(busca);
        await db.SaveChangesAsync();
    }
    await Drenar();
    await using (var db = Context())
        Check(await db.Notificaciones.CountAsync() == 412, "Adopción en ambos sentidos, sin fecha, sin duplicados");
    // Rollback conjunto de aviso y tarea.
    var rollback = Aviso(a, 1);
    await using (var db = Context())
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        new PublicacionRepository(db).Agregar(rollback);
        await db.SaveChangesAsync();
        await tx.RollbackAsync();
    }
    await using (var db = Context())
        Check(!await db.PublicacionesMascotas.AnyAsync(x => x.Id == rollback.Id)
            && !await db.NotificacionesPendientes.AnyAsync(x => x.PublicacionId == rollback.Id), "Aviso y tarea se guardan atómicamente");
    // Edición con contexto nuevo por solicitud; la API usa el mismo servicio.
    PublicacionService Publicaciones(AppDbContext db) => new(new PublicacionRepository(db), new AuthRepository(db));
    EditarPublicacionRequest Editar(PublicacionDto p) => new() {
        Version = p.Version, TipoMascota = p.TipoMascota, Tamano = p.Tamano, Raza = p.Raza,
        Pelaje = p.Pelaje, ColorPredominante = p.ColorPredominante, ColorOjos = p.ColorOjos,
        NombreMascota = p.NombreMascota, Descripcion = p.Descripcion, LocalidadId = p.LocalidadId,
        Zona = p.Zona, InformacionContacto = p.InformacionContacto, FechaSuceso = p.FechaSuceso
    };
    PublicacionDto original;
    await using (var db = Context()) original = await Publicaciones(db).PorIdAsync(origen.Id, ct);
    var edit = Editar(original);
    edit.InformacionContacto = "Contacto corregido";
    PublicacionDto updated;
    await using (var db = Context())
    {
        updated = await Publicaciones(db).EditarAsync(origen.Id, a.Id, edit, ct);
        Check(updated.Version != original.Version && updated.FechaActualizacion != null
            && updated.FechaCreacion == original.FechaCreacion, "Edición conserva creación y cambia versión/actualización");
        Check(!await db.NotificacionesPendientes.AnyAsync(), "Editar contacto no encola revisión");
    }
    await using (var db = Context())
    {
        try { await Publicaciones(db).EditarAsync(origen.Id, a.Id, edit, ct); throw new Exception("Aceptó edición vieja"); }
        catch (AppException ex) when (ex.StatusCode == 409) { Console.WriteLine("OK: versión vieja rechazada"); }
    }
    edit = Editar(updated); edit.Tamano = 2;
    await using (var db = Context())
    {
        updated = await Publicaciones(db).EditarAsync(origen.Id, a.Id, edit, ct);
        Check(await db.NotificacionesPendientes.CountAsync() == 1, "Editar características encola revisión");
    }
    edit = Editar(updated); edit.Tamano = 3;
    await using (var db = Context())
    {
        updated = await Publicaciones(db).EditarAsync(origen.Id, a.Id, edit, ct);
        Check(await db.NotificacionesPendientes.CountAsync() == 1, "Editar con tarea pendiente no la duplica");
    }
    await Drenar();
    await using (var db = Context())
        Check(await db.Notificaciones.CountAsync() == 412, "Edición sin candidatos nuevos conserva historial sin duplicados");
    // Dos solicitudes cargaron la misma versión antes de guardar.
    await using (var db1 = Context())
    await using (var db2 = Context())
    {
        var repo1 = new PublicacionRepository(db1); var repo2 = new PublicacionRepository(db2);
        var p1 = (await repo1.PorIdAsync(origen.Id, ct))!;
        var p2 = (await repo2.PorIdAsync(origen.Id, ct))!;
        p1.Descripcion = "Primera edición concurrente";
        p2.Descripcion = "Segunda edición concurrente";
        await repo1.GuardarEdicionAsync(p1, false, ct);
        try { await repo2.GuardarEdicionAsync(p2, true, ct); throw new Exception("Pisó edición concurrente"); }
        catch (AppException ex) when (ex.StatusCode == 409) { Console.WriteLine("OK: EF evita pérdida de actualización concurrente"); }
    }
    // Simula al worker borrando la tarea mientras una edición espera su bloqueo.
    await using (var lockDb = Context())
    await using (var editDb = Context())
    {
        await using var tx = await lockDb.Database.BeginTransactionAsync();
        await lockDb.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(72409101)");
        var repo = new PublicacionRepository(editDb);
        var p = (await repo.PorIdAsync(origen.Id, ct))!;
        p.Tamano = TamanoMascota.Mediano;
        var saving = repo.GuardarEdicionAsync(p, true, ct);
        await lockDb.NotificacionesPendientes.Where(x => x.PublicacionId == origen.Id).ExecuteDeleteAsync();
        await tx.CommitAsync();
        await saving;
        Check(await editDb.NotificacionesPendientes.AnyAsync(x => x.PublicacionId == origen.Id), "Worker y edición no pierden la revisión pendiente");
    }
    await Drenar();
    await using (var db = Context()) updated = await Publicaciones(db).ResolverAsync(origen.Id, a.Id, ct);
    edit = Editar(updated); edit.Tamano = 1;
    await using (var db = Context())
    {
        updated = await Publicaciones(db).EditarAsync(origen.Id, a.Id, edit, ct);
        Check(updated.Estado == 2 && !await db.NotificacionesPendientes.AnyAsync(), "Editar resuelta no reabre ni encola");
    }
}
finally
{
    NpgsqlConnection.ClearAllPools();
    await using var drop = new NpgsqlCommand($"DROP DATABASE {database} WITH (FORCE)", admin);
    await drop.ExecuteNonQueryAsync();
}
