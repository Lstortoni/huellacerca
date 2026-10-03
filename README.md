# Huella Cerca

App de mascotas perdidas/encontradas y recomendaciones de servicios, inicialmente para Argentina.

## Desarrollo con Docker

La API se restaura, compila y ejecuta dentro de contenedores Linux. No hace falta ejecutar dotnet en Windows para este flujo. Requiere Docker Desktop iniciado.

Desde esta carpeta, para una instalación nueva, copiar `.env.example` como `.env` y ajustar los valores locales. No sobrescribir un `.env` existente. El archivo `.env` está excluido de Git; la contraseña de ejemplo es únicamente para desarrollo local.

```powershell
docker compose up -d --build
```

- API: http://localhost:5080/health (respuesta esperada: HTTP 200, Healthy).
- Swagger: http://localhost:5080/swagger (habilitado en Development).
- PostgreSQL desde Windows: localhost:5435. Usuario, contraseña y base definidos en `.env`.
- Desde la API: huellacerca_db:5432.

Los puertos se publican únicamente en la interfaz local de la PC. Para probar posteriormente desde un teléfono físico habrá que configurar el acceso desde la red local.

Compose crea el grupo `huellacerca`, con servicios `huellacerca_api` y `huellacerca_db`, red y volumen propios, independientes de IdeasProyectos. PostgreSQL conserva sus datos en `huellacerca_huellacerca_db_data`. La API espera a que PostgreSQL esté disponible.

### Después de modificar la API

```powershell
docker compose up -d --build --no-deps huellacerca_api
```

Esto reconstruye y recrea la API sin reiniciar la base. Docker reutiliza las capas de compilación que no cambiaron. Si cambió el modelo y hay migraciones nuevas, usar el flujo de ubicación descrito abajo antes de reiniciar la API.

### Estado, logs y detención

```powershell
docker compose ps
docker compose logs --tail 100 -f huellacerca_api
docker compose down
```

`down` conserva el volumen de datos. No usar `down -v` salvo que se quiera borrar la base local. Las variables POSTGRES inicializan una base nueva; cambiar la contraseña en `.env` no cambia la de una base ya creada.

## Estructura de la API

Solución: `backend/HuellaCerca.sln`, basada en la organización de IdeasProyectos.

| Proyecto | Responsabilidad |
| --- | --- |
| HuellaCerca.API | Endpoints HTTP y configuración. |
| HuellaCerca.MODEL | Ubicación, Usuario, Mascotero, sesiones, rubros, prestadores y recomendaciones. |
| HuellaCerca.CONTRACT | DTO de solicitudes y respuestas. |
| HuellaCerca.INTERFACES | Interfaces de servicios y persistencia. |
| HuellaCerca.SERVICES | Lógica de negocio. |
| HuellaCerca.INFRASTRUCTURE | DbContext, configuraciones, migraciones y repositorio EF Core. |
| HuellaCerca.GeoRefImporter | Ejecutable para importar GeoRef o aplicar migraciones. |

API referencia SERVICES e INFRASTRUCTURE; ambas referencian INTERFACES, que referencia MODEL y CONTRACT.

`backend/Dockerfile` construye la solución con el SDK .NET 8 y publica la API en una imagen de runtime. `Dockerfile.postgres` usa PostgreSQL 16 y conserva el alias de zona horaria de Buenos Aires del proyecto de referencia.

## Estado y próximos pasos

La API consulta los catálogos mediante EF Core. `/health` comprueba que la API responde, no la conexión a PostgreSQL. Las consultas de ubicación son públicas y de solo lectura.

Usuario y Mascotero tienen relación uno a uno. Registro, login JWT, renovación, cierre de sesión y recomendaciones básicas están implementados. Publicaciones de mascotas incluye modelo, migración, DTO, repositorio, servicio y endpoints de creación sin fotos, búsqueda pública, detalle y resolución exclusiva del autor. La subida de imágenes queda pendiente. Tampoco hay verificación de email, recuperación de contraseña, comentarios ni me gusta. La app Flutter tiene inicio público con tarjetas y agrega acciones de participación cuando hay sesión. Están conectados autenticación, perfil, ubicación, búsqueda y detalle de mascotas/recomendaciones, publicación de mascotas y resolución del autor, y recomendaciones con selección o creación de prestador.

## Ubicación: primera carga

`docker compose up -d --build` inicia PostgreSQL, ejecuta `huellacerca_migrations` y levanta la API solo si las migraciones terminan correctamente. El contenedor de migraciones termina con código 0; es normal verlo detenido. No descarga GeoRef en cada arranque.

Para cargar o actualizar el catálogo:

```powershell
docker compose --profile tools run --rm --build huellacerca_importer
```

Fuente: [GeoRef de Argentina](https://www.argentina.gob.ar/georef). Se utiliza el recurso de **localidades censales**, igual que en IdeasProyectos; no representa todos los barrios o asentamientos. El importador pagina usando `inicio` y `max`, verifica totales e identificadores y descarga todo antes de modificar la base. Guarda los cambios en una transacción y serializa importaciones concurrentes mediante un bloqueo de PostgreSQL.

Las ejecuciones posteriores actualizan por GeorefId y conservan los UUID locales. No elimina registros ausentes del catálogo recibido. Los registros presentes se marcan activos; una desactivación manual puede revertirse al importar. Si la descarga o validación falla, termina con error sin aplicar una carga parcial. Reintenta fallos HTTP transitorios hasta dos veces.

### Endpoints

- `GET /api/paises`: países activos.
- `GET /api/provincias?paisCodigo=AR`: provincias activas; AR es el valor predeterminado.
- `GET /api/localidades?provinciaId=UUID&busqueda=cordoba&pagina=1&tamanoPagina=20`: localidades activas, búsqueda parcial sin distinguir acentos o mayúsculas.

Localidades devuelve `items`, `total`, `pagina` y `tamanoPagina`. ProvinciaId es obligatorio; tamaño de página entre 1 y 100, por defecto 20. Los parámetros inválidos devuelven 400; una provincia inexistente o inactiva, 404. Una búsqueda sin coincidencias devuelve 200 con una lista vacía. Los DTO no exponen propiedades de navegación ni ciclos de EF.

### Crear una migración futura sin dotnet en Windows

Después de cambiar modelos/configuraciones:

```powershell
docker compose --profile tools build huellacerca_tools
docker compose run --rm --no-deps huellacerca_tools ef migrations add NombreDelCambio --project HuellaCerca.INFRASTRUCTURE --startup-project HuellaCerca.INFRASTRUCTURE --output-dir Migrations --msbuildprojectextensionspath /tmp/huellacerca-build/HuellaCerca.INFRASTRUCTURE/obj
docker compose up -d --build
```

La herramienta usa un montaje de `backend/` para guardar la migración en el repositorio. EF Core y dotnet-ef se ejecutan dentro de Docker. Revisar y versionar las migraciones generadas antes del despliegue.

Las herramientas usan `/tmp/huellacerca-build` para sus archivos intermedios, separados de `obj/` y `bin/` de Windows. Esto evita que VS Code intente resolver paquetes mediante rutas Linux. El argumento `--msbuildprojectextensionspath` debe acompañar los comandos de EF Core.

Para IntelliSense en VS Code sobre Windows, restaurar las referencias locales con `dotnet restore backend/HuellaCerca.sln` desde la raíz (requiere SDK local). Esto descarga referencias del editor; no compila ni ejecuta la API. Si el editor conserva diagnósticos antiguos, usar **Developer: Reload Window**.

### Pruebas del bloque

Con la API levantada y el catálogo importado:

```powershell
docker compose run --rm --no-deps huellacerca_tests
```

Ejecuta pruebas HTTP de solo lectura desde un contenedor Python, sin instalar Python ni ejecutar scripts locales en Windows. Verifica catálogo, filtro por provincia, búsqueda con/sin acentos, paginación, respuesta vacía, Swagger y errores 400/404.

### Recorrido del código

1. `API/Controllers/UbicacionController.cs` recibe HTTP y valida parámetros.
2. `SERVICES/UbicacionService.cs` coordina la consulta y transforma entidades a DTO.
3. `INTERFACES/` define los contratos del servicio y repositorio.
4. `INFRASTRUCTURE/Repositories/UbicacionRepository.cs` consulta con EF Core sin seguimiento de cambios.
5. `INFRASTRUCTURE/Data/AppDbContext.cs` y `Configuration/` describen tablas, relaciones e índices.
6. `MODEL/` contiene entidades; `CONTRACT/Ubicacion/`, los datos de entrada y salida.
7. `GeoRefImporter/GeorefImporter.cs` descarga, valida y guarda el catálogo.

Las rutas anteriores son relativas a los proyectos `backend/HuellaCerca.*`.

## Registro, sesiones y recomendaciones

Consultar [la guía de endpoints y ejemplos](docs/api-comunidad.md).

En una instalación nueva, configurar `JWT_KEY` en `.env` con un secreto aleatorio de al menos 32 bytes. El valor de `.env.example` es un marcador que debe reemplazarse; la API lo rechaza. En este equipo ya se generó una clave local, sin incluirla en Git.

Valores iniciales: JWT de 15 minutos y refresh de 30 días. La renovación conserva el vencimiento absoluto de la sesión, rota el refresh y rechaza su reutilización. No hay renovación infinita. Cada login crea una sesión independiente.

Para ejecutar las pruebas HTTP de comunidad:

```powershell
docker compose run --rm --no-deps huellacerca_tests python /tests/test_comunidad.py
```

Estas pruebas crean dos cuentas y prestadores identificados con `hc-test-...` y eliminan las recomendaciones que publican. Las cuentas y fichas de prueba quedan en la base local. No ejecutar contra producción. El contenedor de pruebas recibe la clave JWT local para probar tokens firmados con vencimiento, emisor y audiencia incorrectos; no imprime tokens ni contraseñas.

El cierre de sesión revoca los refresh de esa sesión. El JWT ya emitido puede funcionar hasta su vencimiento. En cada petición autenticada también se consulta si el usuario sigue activo y si corresponde al mascotero del token; desactivar al usuario bloquea el acceso sin esperar el vencimiento.

Los endpoints de autenticación tienen un límite de 60 solicitudes por minuto por IP y devuelven 429 al superarlo. Es un límite local en memoria; una instalación con varias réplicas necesitará control compartido. La API local usa HTTP; el despliegue externo deberá servir autenticación mediante HTTPS.

El proyecto Flutter está en `mobile/`, con inicio público y una barra de cuenta compartida. Incluye ingreso, registro con provincia/localidad, perfil de solo lectura, almacenamiento seguro de sesión, renovación y cierre de sesión. Consultar [la guía de Flutter](mobile/README.md) para ejecutarlo, configurar la URL, entender sus carpetas y probar el recorrido completo contra la API local.

.NET 8 se conserva inicialmente por coherencia con el proyecto de referencia. Revisar la versión objetivo y su soporte antes del despliegue.

## Modelo de publicaciones de mascotas

Consultar [entidades, relaciones y próximos pasos](docs/publicaciones-mascotas.md).
## Recomendaciones positivas con aspectos

`Recomendacion` une un Mascotero con un PrestadorServicio y mantiene sus fechas.
Una restricción única en PostgreSQL impide más de una por ese par.
`AspectoRecomendacion` es el catálogo del sistema (seis aspectos iniciales).
`RecomendacionAspecto` vincula cada recomendación con cero o varios aspectos, con clave compuesta.

POST de una ficha ya recomendada devuelve 200 con la recomendación existente, sin borrar aspectos. Una nueva devuelve 201. El alta conjunta de prestador y recomendación es transaccional.
Los aspectos se reemplazan con PUT; eliminar todos no retira el voto.
Los conteos se calculan desde los votos y sus relaciones, sin columnas de totales que puedan quedar desactualizadas.

- Público: GET /api/prestadores, /api/prestadores/{id}, /api/prestadores/similares, /api/aspectos-recomendacion.
- Con JWT: POST /api/recomendaciones, GET /api/recomendaciones/mias, GET /api/recomendaciones/{id}, PUT /api/recomendaciones/{id}/aspectos, DELETE /api/recomendaciones/{id}.
- Se retiraron GET /api/recomendaciones y el PUT de texto libre. Actualizar la app junto con la API.

Servicios recomendados es una consulta pública de solo lectura: solo lista fichas con votos y muestra cantidades, aspectos y nombres de los mascoteros. GET /api/prestadores/{id}/recomendadores devuelve esos nombres paginados, sin datos privados de contacto. La edición de aspectos y el retiro del voto quedan en el recorrido Recomendar un servicio. Las fichas sin votos siguen disponibles en similares para evitar crear otra al recomendarlas nuevamente.

### Migración de recomendaciones existentes

`20260918163431_RecomendacionesConAspectos` copia las recomendaciones previas a `recomendaciones_textos_respaldo` antes de quitar Titulo/Descripcion.
El respaldo conserva todos los datos originales, la fecha del respaldo y el ID que se conserva para cada par mascotero/prestador.
Si había varias recomendaciones del mismo par, conserva como voto la más antigua (desempate por ID); las anteriores quedan sin aspectos.
El respaldo no está expuesto en la API ni modelado por EF.

La migración corre en una transacción con bloqueo de la tabla. No modifica migraciones anteriores.
**No tiene Down automático**: restaurar la versión anterior requiere una operación explícita y un respaldo completo de la base; el archivo de textos no incluye cambios posteriores ni reemplaza un backup.
No eliminar el volumen Docker para migrar. El servicio huellacerca_migrations aplica el cambio antes de iniciar la API.

### Push por coincidencias (Firebase)

La integración Android registra dispositivos por sesión y la API encola envíos al generar
notificaciones internas. Configuración de la cuenta de servicio, flujo por archivo y pruebas:
[Notificaciones push](docs/push-firebase.md). Está deshabilitada por defecto en el backend hasta
colocar `secrets/firebase-admin.json` y habilitar `FIREBASE_PUSH_ENABLED` en `.env`.
