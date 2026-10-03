# Notificaciones push: recorrido y configuración

## Qué quedó implementado

Android: registro del dispositivo con sesión, rotación de token, desvinculación al salir,
envío desde la API por coincidencias, reintentos, mensaje dentro de la app y apertura
del detalle al tocar una notificación. iOS sigue pendiente de configurar en Firebase y APNs;
el registro del backend ya acepta `ios`, pero la app habilita esta integración solo en Android.

La campanita y sus consultas HTTP siguen funcionando aunque Firebase esté deshabilitado.
No usamos Firebase Auth: el login y JWT siguen siendo los de Huella Cerca.

## 1. Al abrir la app e iniciar sesión

1. `mobile/lib/main.dart` inicializa Firebase y llama a `configurarServicios(habilitarPush: true)` en Android.
2. `core/di/service_registration.dart` registra `MensajeriaPush → MensajeriaPushFirebase`
   y `PushService → PushServiceApi`. Las páginas no dependen directamente de Firebase.
3. `app.dart`, después de mostrar la primera pantalla, llama a `PushService.iniciar()`.
4. `PushServiceApi` escucha `AuthService`. Al restaurar/iniciar sesión, llama a `sincronizar()`.
5. `MensajeriaPushFirebase` obtiene/crea un GUID de instalación guardado en almacenamiento seguro,
   pide permiso una vez y obtiene el token FCM. El GUID no es el token ni identifica al mascotero.
6. `PushServiceApi` llama a `AuthService.putProtegido()` con el token y la plataforma.
7. HTTP `PUT /api/dispositivos-push/{instalacionId}` con JWT llega a `DispositivosPushController`.
8. El controller obtiene el mascotero y `sid` de los claims; llama a `PushService.RegistrarAsync()`.
9. `PushRepository.RegistrarAsync()` verifica que la sesión siga activa y guarda/actualiza `DispositivoPush`.

Repetir el registro es válido. Una cuenta puede tener varios dispositivos; una instalación
queda asociada a una sola cuenta/sesión. Un cambio de token, cuenta o sesión renueva `Version`.
`onTokenRefresh` vuelve a sincronizar. Los fallos de registro se reintentan al minuto y al volver a la app.
El permiso denegado desactiva el registro; se puede habilitar desde Ajustes de Android.
Ya no se imprimen tokens en consola y se eliminó la función temporal `prepararPruebaPush`.

## 2. Cuando se publica y hay coincidencias

1. El flujo existente guarda `PublicacionMascota` y `NotificacionPendiente`.
2. `ProcesarNotificaciones` ejecuta `NotificacionRepository.ProcesarLoteAsync()`.
3. Por cada coincidencia nueva, `InsertarAsync()` guarda la notificación interna.
4. **En la misma transacción**, inserta un `EnvioPush` por dispositivo activo del destinatario
   con sesión vigente. Si la notificación ya existía, no vuelve a encolar push.
5. `EnviarNotificacionesPush` consulta la cola cada 5 segundos (continúa inmediatamente si procesó un envío).
6. `PushService.ProcesarAsync()` pide a `PushRepository.ReservarAsync()` un envío.
7. El repository descarta dispositivos desvinculados, cambios de cuenta/token, sesiones vencidas/revocadas,
   usuarios inactivos, avisos ya leídos y envíos de más de 24 horas.
8. Reserva el envío durante 2 minutos, libera la transacción y llama a `IEmisorPush`.
9. `FirebaseEmisorPush` usa Firebase Admin para enviar título, texto genérico e IDs de navegación.
10. `CompletarAsync()` registra el resultado. Firebase aceptó el mensaje no significa que el usuario lo leyó.

Los errores transitorios se reintentan con espera creciente, hasta 5 intentos. Un token no registrado
en Firebase desactiva solamente ese dispositivo. Una caída del proceso permite recuperar la reserva.
No hay garantía de entrega exactamente una vez: si Firebase acepta y la API cae antes de registrar el
resultado, puede reintentarse. Se usa el ID de notificación como `tag` de Android para reemplazar el mismo aviso.

Solo se envían coincidencias **nuevas** a dispositivos registrados al generarlas. No se envía automáticamente
todo el historial al iniciar sesión. Los envíos finalizados se conservan para diagnóstico.

## 3. Cómo lo recibe la app

- Segundo plano/cerrada: Android muestra la notificación enviada por Firebase (con permiso concedido).
- Primer plano: `onMessage` llega a `PushServiceApi`, que filtra por mascotero activo.
  `app.dart` actualiza la campanita y muestra un mensaje con botón **Ver**.
- Al tocar el aviso: `onMessageOpenedApp` o `getInitialMessage` pasa los datos a `app.dart`.
  Si falta sesión se abre login. Si la cuenta es otra, no se abre el aviso.
- Se consulta `GET /api/notificaciones/{id}/destino` con JWT: la API comprueba propiedad y devuelve
  el ID real de la publicación coincidente. Después se marca leída y se abre `PublicacionDetallePage`.
- Si falla la conexión, el aviso sigue accesible desde la campanita.

## 4. Cierre de sesión

`AuthServiceApi.logout()` llama al callback `antesDeLogout` registrado en DI, que ejecuta
`PushService.desvincular()` **antes** de borrar la sesión. Espera cualquier registro en vuelo,
envía DELETE autenticado y elimina el token de Firebase. Luego continúa el logout habitual.
El worker también comprueba la sesión en base: una sesión revocada no recibe nuevos envíos.
Si no hay conexión se permite salir localmente y se informa que no se pudo confirmar la desvinculación.
No se pueden retirar mensajes ya entregados o en vuelo; el texto push es genérico y al abrir siempre
se comprueba la cuenta. Sin conexión, la revocación remota inmediata no está garantizada.

## Entidades nuevas y migración

`DispositivoPush`: Id (instalación), MascoteroId, SesionId, Token, Plataforma, Activo,
Version, FechaActualizacion.

`EnvioPush`: Id, NotificacionId, DispositivoPushId, VersionDispositivo, FechaCreacion,
ProximoIntento, Intentos, Reserva, FechaFinalizacion, Resultado.

Migración: `DispositivosYEnviosPush`. No elimina notificaciones ni publicaciones existentes.

## Configuración del backend (pendiente de tus credenciales)

El `google-services.json` de Android **no autoriza a la API a enviar mensajes**.
La API necesita un JSON de cuenta de servicio del mismo proyecto Firebase.

1. En Firebase: Configuración del proyecto → Cuentas de servicio → Firebase Admin SDK →
   Generar nueva clave privada. Usar una cuenta con permiso de enviar FCM; verificar que
   Firebase Cloud Messaging API esté habilitada en el proyecto.
2. Crear la carpeta `secrets` en la raíz, junto a `compose.yaml`.
3. Guardar allí el archivo con el nombre **`firebase-admin.json`**. No subirlo a Git ni colocarlo en Flutter.
4. Agregar a `.env`:

```dotenv
FIREBASE_PUSH_ENABLED=true
FIREBASE_PROJECT_ID=huella-cerca
```

5. Desde la raíz:

```powershell
docker compose up -d --build huellacerca_api
```

Compose monta `./secrets` de solo lectura en `/run/huellacerca-secrets` y entrega estas opciones:

```text
FirebasePush__Enabled
FirebasePush__ProjectId
FirebasePush__CredentialsPath=/run/huellacerca-secrets/firebase-admin.json
```

`Program.cs` registra las opciones y `FirebaseEmisorPush` lee la credencial de ese archivo.
El JSON no se copia a la imagen Docker. `secrets/` y los nombres habituales de claves están ignorados por Git.
Sin habilitar la opción, el emisor queda apagado y la API funciona normalmente. Si se habilita y falta
el archivo, la API informa un error de configuración al arrancar.

## Prueba completa (la app la instalás vos)

Desde `mobile`, ejecutar `flutter run -d emulator-5554`. Iniciar sesión y aceptar notificaciones.
Usar dos cuentas: A publica un aviso y B publica uno compatible. Para ver una notificación del sistema,
dejar la app de A en segundo plano antes de crear B. Debe haber misma especie/localidad y los criterios
del buscador de coincidencias; no se cambió esa lógica.
Esperar el procesamiento, tocar el aviso y comprobar que abre la publicación de B.
Repetir con la app abierta (mensaje **Ver**) y después de cerrar sesión (no nuevos envíos a esa sesión).
Para comprobar varios dispositivos, iniciar la misma cuenta en dos instalaciones.

Logs de API:

```powershell
docker compose logs --tail 100 huellacerca_api
```

Buscar `Push ... aceptado por Firebase` o `Firebase ...` con el código de error.
Los logs no imprimen tokens ni claves privadas. `EnviosPush.Resultado` permite distinguir enviado,
token inválido, reintento, expirado, leído o dispositivo desvinculado.

Referencias: [Firebase Admin](https://firebase.google.com/docs/admin/setup),
[recepción en Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).
