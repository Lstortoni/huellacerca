using HuellaCerca.CONTRACT.Notificaciones;
using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INFRASTRUCTURE.Repositories;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.MODEL;
using HuellaCerca.SERVICES;
using Microsoft.EntityFrameworkCore;

internal static class PushChecks
{
    public static async Task Run(Func<AppDbContext> context, Guid localidadId)
    {
        var ct = CancellationToken.None;
        void Check(bool ok, string message) { if (!ok) throw new Exception(message); Console.WriteLine("OK Push: " + message); }
        var autor = new Mascotero { Nombre = "Push", Apellido = "Test", LocalidadId = localidadId };
        var otro = new Mascotero { Nombre = "Otro", Apellido = "Test", LocalidadId = localidadId };
        var usuario = new Usuario { Mascotero = autor, Email = "push@test.invalid", PasswordHash = "test" };
        var usuario2 = new Usuario { Mascotero = otro, Email = "push2@test.invalid", PasswordHash = "test" };
        var sesion = Guid.NewGuid(); var sesion2 = Guid.NewGuid();
        RefreshToken Refresh(Usuario user, Guid session) => new() { Usuario = user, SesionId = session, TokenHash = Guid.NewGuid().ToString(),
            FechaCreacion = DateTime.UtcNow, FechaExpiracion = DateTime.UtcNow.AddDays(1) };
        var dispositivo = Guid.NewGuid(); var segundo = Guid.NewGuid();
        var token = new RegistrarDispositivoRequest { Token = "token-de-prueba-123456789" };
        PublicacionMascota Aviso(Mascotero m, TipoPublicacionMascota tipo) => new() {
            MascoteroId = m.Id, LocalidadId = localidadId, TipoPublicacion = tipo,
            TipoMascota = TipoMascota.Gato, Tamano = TamanoMascota.Grande,
            FechaSuceso = new DateOnly(2026, 9, 20), Descripcion = "Prueba push", InformacionContacto = "Prueba", Zona = "Prueba"
        };
        var perdida = Aviso(autor, TipoPublicacionMascota.Perdida);
        var encontrada = Aviso(otro, TipoPublicacionMascota.Encontrada);
        await using (var db = context())
        {
            db.RefreshTokens.AddRange(Refresh(usuario, sesion), Refresh(usuario2, sesion2));
            db.PublicacionesMascotas.AddRange(perdida, encontrada);
            await db.SaveChangesAsync();
            var repo = new PushRepository(db);
            await repo.RegistrarAsync(dispositivo, autor.Id, sesion, token, ct);
            var version = (await db.DispositivosPush.SingleAsync(x => x.Id == dispositivo)).Version;
            await repo.RegistrarAsync(dispositivo, autor.Id, sesion, token, ct);
            Check(await db.DispositivosPush.CountAsync() == 1 && (await db.DispositivosPush.SingleAsync()).Version == version,
                "registro repetido no duplica ni invalida envíos pendientes");
            await repo.RegistrarAsync(segundo, autor.Id, sesion, new() { Token = "segundo-token-prueba-123456" }, ct);
            await repo.DesactivarAsync(dispositivo, otro.Id, sesion2, ct);
            Check(await db.DispositivosPush.AnyAsync(x => x.Id == dispositivo && x.Activo), "otra cuenta no puede desvincular dispositivo");
            try { await repo.RegistrarAsync(Guid.NewGuid(), otro.Id, sesion, token, ct); throw new Exception("Aceptó sesión ajena"); }
            catch (AppException e) when (e.StatusCode == 401) { }
            db.NotificacionesPendientes.Add(new() { PublicacionId = perdida.Id });
            await db.SaveChangesAsync();
        }
        await using (var db = context()) await new NotificacionRepository(db).ProcesarLoteAsync(ct);
        await using (var db = context())
        {
            Check(await db.EnviosPush.CountAsync() == 2, "una notificación genera un envío por dispositivo; destinatario sin dispositivo conserva interna");
            db.NotificacionesPendientes.Add(new() { PublicacionId = encontrada.Id }); await db.SaveChangesAsync();
        }
        await using (var db = context()) await new NotificacionRepository(db).ProcesarLoteAsync(ct);
        await using (var db = context()) Check(await db.EnviosPush.CountAsync() == 2, "reprocesar coincidencia no duplica push");

        TrabajoPush trabajo;
        await using (var db = context()) trabajo = (await new PushRepository(db).ReservarAsync(ct))!;
        await using (var db = context())
        {
            var siguiente = (await new PushRepository(db).ReservarAsync(ct))!;
            Check(siguiente.Id != trabajo.Id, "reserva persistida impide que otro worker tome el mismo envío");
            await new PushRepository(db).CompletarAsync(siguiente, ResultadoPush.Enviado, ct);
            await new PushRepository(db).CompletarAsync(trabajo, ResultadoPush.Reintentar, ct);
            var fila = await db.EnviosPush.AsNoTracking().SingleAsync(x => x.Id == trabajo.Id);
            Check(fila.FechaFinalizacion == null && fila.ProximoIntento > DateTime.UtcNow && fila.Intentos == 1,
                "fallo transitorio conserva envío y programa reintento");
            await db.EnviosPush.Where(x => x.Id == trabajo.Id).ExecuteUpdateAsync(s => s.SetProperty(x => x.ProximoIntento, DateTime.UtcNow.AddSeconds(-1)));
        }
        await using (var db = context())
        {
            var fake = new EmisorFake { Resultado = ResultadoPush.TokenInvalido };
            await new PushService(new PushRepository(db), fake).ProcesarAsync(ct);
            Check(fake.Envios == 1 && !await db.DispositivosPush.AnyAsync(x => x.Id == trabajo.DispositivoId && x.Activo),
                "token inválido desactiva solamente ese dispositivo");
        }
        // Crear un envío y luego cambiar la cuenta del dispositivo: no debe recibir el pendiente anterior.
        Guid nuevaNotificacion;
        await using (var db = context())
        {
            var repo = new PushRepository(db);
            await repo.RegistrarAsync(dispositivo, autor.Id, sesion, token, ct);
            var n = new Notificacion { MascoteroId = autor.Id, PublicacionId = encontrada.Id, PublicacionCoincidenteId = perdida.Id };
            nuevaNotificacion = n.Id;
            db.Notificaciones.Add(n);
            db.EnviosPush.Add(new() { NotificacionId = n.Id, DispositivoPushId = dispositivo,
                VersionDispositivo = (await db.DispositivosPush.SingleAsync(x => x.Id == dispositivo)).Version });
            await db.SaveChangesAsync();
            await repo.RegistrarAsync(dispositivo, otro.Id, sesion2, token, ct);
        }
        await using (var db = context())
        {
            var fake = new EmisorFake();
            await new PushService(new PushRepository(db), fake).ProcesarAsync(ct);
            Check(fake.Envios == 0 && await db.EnviosPush.AnyAsync(x => x.NotificacionId == nuevaNotificacion && x.Resultado == "DispositivoDesvinculado"),
                "cambio de cuenta cancela pendientes del destinatario anterior");
            Check(await new NotificacionRepository(db).DestinoAsync(otro.Id, nuevaNotificacion, ct) == null,
                "destino del push no revela publicaciones de notificaciones ajenas");
        }
        await using (var db = context())
        {
            var n = await db.Notificaciones.FirstAsync(x => x.MascoteroId == otro.Id && x.PublicacionId == encontrada.Id);
            var d = await db.DispositivosPush.SingleAsync(x => x.Id == dispositivo);
            db.EnviosPush.Add(new() { NotificacionId = n.Id, DispositivoPushId = dispositivo, VersionDispositivo = d.Version });
            await db.SaveChangesAsync();
            await new AuthRepository(db).RevocarSesionAsync(sesion2, DateTime.UtcNow, ct);
        }
        await using (var db = context())
        {
            var fake = new EmisorFake();
            await new PushService(new PushRepository(db), fake).ProcesarAsync(ct);
            Check(fake.Envios == 0, "sesión revocada no recibe push aunque el dispositivo figure activo");
        }
    }

    private sealed class EmisorFake : IEmisorPush
    {
        public bool Habilitado => true;
        public int Envios;
        public ResultadoPush Resultado = ResultadoPush.Enviado;
        public Task<ResultadoPush> EnviarAsync(TrabajoPush trabajo, CancellationToken ct) { Envios++; return Task.FromResult(Resultado); }
    }
}
