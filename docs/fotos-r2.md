# Fotos de publicaciones con Cloudflare R2

Una foto opcional por aviso, para los cuatro tipos. PostgreSQL guarda ObjectKey, nunca los bytes. El bucket es privado; Flutter accede por la API, sin credenciales R2. No se conserva el original pesado.

## Activar tu bucket

Ya tenés el bucket privado `huella-cerca-images` y credenciales S3 con permiso Object Read & Write limitado a ese bucket. No habilitar r2.dev ni acceso público. No se utiliza el valor del Account API Token como contraseña S3: usar Access Key ID y Secret Access Key que entrega Cloudflare.

En el archivo `.env` de la raíz `huellacerca` quedaron preparadas estas variables. Completalas localmente con los datos reales:

```dotenv
R2_ENABLED=true
R2_ENDPOINT=https://TU_ACCOUNT_ID.r2.cloudflarestorage.com
R2_BUCKET=huella-cerca-images
R2_ACCESS_KEY_ID=TU_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY=TU_SECRET_ACCESS_KEY
```

El endpoint debe ser el exacto que muestra Cloudflare (incluye Account ID y puede variar por jurisdicción). No enviar las claves por chat ni agregarlas a Flutter, a appsettings versionado o a `.env.example`.

Desde la raíz `huellacerca`, después de completar las variables:

```powershell
docker compose up -d huellacerca_api
```

La imagen ya queda construida con este cambio. Si también cambiaste código, usar `docker compose up -d --build huellacerca_api`. Compose ejecuta primero las migraciones. Un simple `restart` no recarga las variables de entorno.

Desde `mobile`, el usuario actualiza la app:

```powershell
flutter run -d emulator-5554
```

Con `R2_ENABLED=false` la API sigue funcionando y se puede publicar sin foto. Intentar subir una devuelve 503 con un mensaje claro. No hay fallback al disco del contenedor.

Fuentes: [credenciales R2](https://developers.cloudflare.com/r2/api/tokens/), [integración S3 con .NET](https://developers.cloudflare.com/r2/examples/aws/aws-sdk-net/).

## Dónde está cada parte

| Archivo o carpeta | Responsabilidad |
|---|---|
| `.env` | Credenciales reales, solo locales |
| `.env.example` | Nombres de variables, sin secretos |
| `compose.yaml` | Pasa R2_ENABLED como R2__Enabled y las demás variables al contenedor API |
| `backend/HuellaCerca.API/Program.cs` | Registra servicios y enlaza la sección de configuración R2 |
| `backend/HuellaCerca.API/Controllers/FotosController.cs` | PUT, GET y DELETE de la foto |
| `backend/HuellaCerca.SERVICES/FotoService.cs` | Permisos, procesamiento, subida y actualización de referencia |
| `backend/HuellaCerca.INTERFACES/Services/IFotoService.cs` | Contratos de fotos, almacenamiento y procesador |
| `backend/HuellaCerca.INFRASTRUCTURE/Storage` | Implementación S3/R2 y optimización a WebP |
| `backend/HuellaCerca.INFRASTRUCTURE/Repositories/FotoRepository.cs` | Foto única, concurrencia y cola de limpieza |
| `mobile/lib/services/implementations/selector_fotos_galeria.dart` | Selección y reducción inicial desde galería |
| `mobile/lib/pages/publicar_mascota_page.dart` | Selección, vista previa y creación del aviso |
| `mobile/lib/widgets/foto_publicacion.dart` | Subida pendiente, reintento, reemplazo, borrado y visualización |

## Flujo

Flutter selecciona desde galería con image_picker, solicita reducción a 1280 px/calidad 75 y muestra una vista previa. Envía JSON para crear el aviso y luego PUT multipart para subir la imagen. Si la segunda operación falla, el aviso ya existe: el detalle conserva la selección para reintentar sin duplicarlo. Si se cierra la app, se puede elegir nuevamente la foto desde el detalle. En Android se intenta recuperar una selección interrumpida por el sistema al volver al formulario; el borrador completo no se persiste.

La API acepta JPEG, PNG y WebP reales de hasta 10 MiB y 40 megapíxeles. Verifica firma y decodifica, normaliza orientación, quita metadatos (incluido EXIF/GPS), limita a 1280 px sin agrandar y codifica WebP. Baja calidad y, si hace falta, dimensiones hasta quedar en <=250 KiB. Animaciones se normalizan al primer cuadro. No se admite SVG, PDF ni HEIC directo: si el selector no lo convierte, elegir JPEG/PNG/WebP. La calidad visual se revisa con fotos reales; no se promete un peso exacto de 100 KB.

La clave es `mascotas/{publicacionId}/{guidNuevo}.webp`. El DTO contiene `foto: null` o `{id, url}`; la URL es relativa a la API y lleva una versión. La app la resuelve usando la misma base configurada para los servicios. Se muestra en detalle, búsqueda, Mis publicaciones y coincidencias.

## Reemplazo y limpieza

Migración FotoUnicaR2: colección → referencia opcional Foto, índice único por PublicacionMascotaId, RutaArchivo → ObjectKey, elimina Orden. Si detecta referencias antiguas, aborta sin descartarlas: habría que trasladar primero esos archivos a R2.

Antes de subir se registra una entrada en `fotos_pendientes_limpieza`, con una hora de margen. Se sube a una clave nueva. En una transacción se verifica que nadie haya cambiado la foto, se actualiza la referencia y se programa borrar la anterior. Un conflicto concurrente devuelve 409. Si falla la operación, no se borra la foto anterior.

Un proceso revisa pendientes cada cinco minutos. Solo elimina claves no referenciadas y reintenta tras fallos o reinicios. Al eliminar una foto desaparece de la API inmediatamente; el borrado físico en R2 es diferido. No cambiar el bucket configurado sin planificar el traslado de las referencias existentes.

## Pruebas

Publicar sin foto; publicar con foto; abrir un aviso anterior y agregar/reemplazar/eliminar. Abrir con otro usuario: no puede modificarla. Simular fallo de conexión: el aviso permanece y Reintentar foto no duplica la publicación.

```powershell
docker compose run --rm --no-deps huellacerca_tools run --project HuellaCerca.Fotos.Tests
```

Estas pruebas usan PostgreSQL y almacenamiento simulado para validar fallos/concurrencia. Dejan una cuenta hc-photo-test-* y un aviso resuelto, limpiando sus fotos. No prueban acceso a tu bucket: eso se verifica subiendo una foto después de completar `.env`. Los ejemplos de Postman están en PruebasApi.md.
