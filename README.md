# Huella Cerca

App de mascotas perdidas/encontradas y recomendaciones de servicios, inicialmente para Argentina.

## Desarrollo con Docker

La API se restaura, compila y ejecuta dentro de contenedores Linux. No hace falta ejecutar dotnet en Windows para este flujo. Requiere Docker Desktop iniciado.

Desde esta carpeta, para una instalación nueva, copiar `.env.example` como `.env` y ajustar los valores locales. No sobrescribir un `.env` existente. El archivo `.env` está excluido de Git; la contraseña de ejemplo es únicamente para desarrollo local.

```powershell
docker compose up -d --build
```

- API: http://localhost:5080/health (respuesta esperada: HTTP 200, Healthy).
- PostgreSQL desde Windows: localhost:5435. Usuario, contraseña y base definidos en `.env`.
- Desde la API: huellacerca_db:5432.

Los puertos se publican únicamente en la interfaz local de la PC. Para probar posteriormente desde un teléfono físico habrá que configurar el acceso desde la red local.

Compose crea el grupo `huellacerca`, con servicios `huellacerca_api` y `huellacerca_db`, red y volumen propios, independientes de IdeasProyectos. PostgreSQL conserva sus datos en `huellacerca_huellacerca_db_data`. La API espera a que PostgreSQL esté disponible.

### Después de modificar la API

```powershell
docker compose up -d --build --no-deps huellacerca_api
```

Esto reconstruye y recrea la API sin reiniciar la base. Docker reutiliza las capas de compilación que no cambiaron.

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
| HuellaCerca.MODEL | Entidades pendientes de definir. |
| HuellaCerca.CONTRACT | DTO de solicitudes y respuestas. |
| HuellaCerca.INTERFACES | Interfaces de servicios y persistencia. |
| HuellaCerca.SERVICES | Lógica de negocio. |
| HuellaCerca.INFRASTRUCTURE | Persistencia e integraciones; alojará EF Core. |

API referencia SERVICES e INFRASTRUCTURE; ambas referencian INTERFACES, que referencia MODEL y CONTRACT.

`backend/Dockerfile` construye la solución con el SDK .NET 8 y publica la API en una imagen de runtime. `Dockerfile.postgres` usa PostgreSQL 16 y conserva el alias de zona horaria de Buenos Aires del proyecto de referencia.

## Estado y próximos pasos

La API y PostgreSQL se ejecutan en Docker. La cadena de conexión está preparada, pero la API todavía no la consume: no hay DbContext, modelos, migraciones, autenticación ni Swagger. `/health` comprueba que la API responde, no la conexión a PostgreSQL.

Después de definir el modelo incorporaremos EF Core, registro/login JWT, catálogos geográficos e importador GeoRef adaptados de IdeasProyectos. Las migraciones y el importador también deberán ejecutarse dentro de Docker.

El proyecto Flutter está en `mobile/`, con la pantalla del contador como primera práctica. Consultar `mobile/README.md` para ejecutarlo y entender sus archivos. Todavía no se conecta a la API; cuando incorporemos datos, consumirá exclusivamente sus endpoints.

.NET 8 se conserva inicialmente por coherencia con el proyecto de referencia. Revisar la versión objetivo y su soporte antes del despliegue.
