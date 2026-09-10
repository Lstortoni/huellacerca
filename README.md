# Huella Cerca

Aplicación móvil para mascotas perdidas/encontradas y recomendaciones de servicios, inicialmente para Argentina.

## Estado actual

Estructura inicial de la API ASP.NET Core 8, siguiendo la organización de IdeasProyectos. Todavía no incluye entidades, autenticación, EF Core, base de datos ni Docker. Flutter se incorporará posteriormente en `mobile/`.

## Backend

La solución está en `backend/HuellaCerca.sln`:

| Proyecto | Responsabilidad |
| --- | --- |
| HuellaCerca.API | Endpoints HTTP y configuración de la aplicación. |
| HuellaCerca.MODEL | Entidades del dominio, pendientes de definir. |
| HuellaCerca.CONTRACT | DTO de solicitudes y respuestas. |
| HuellaCerca.INTERFACES | Interfaces de servicios y acceso a datos. |
| HuellaCerca.SERVICES | Lógica de negocio. |
| HuellaCerca.INFRASTRUCTURE | Implementaciones de persistencia e integraciones; alojará EF Core. |

API referencia SERVICES e INFRASTRUCTURE; ambas referencian INTERFACES, que referencia MODEL y CONTRACT. Las capas están vacías hasta definir las primeras funcionalidades.

### Ejecutar desde PowerShell

Requiere el SDK .NET 8.0.420 (o un parche posterior de la misma banda), seleccionado en `backend/global.json`.

Desde la carpeta raíz:

```powershell
cd backend
dotnet build HuellaCerca.sln
dotnet run --project HuellaCerca.API --launch-profile http
```

En otra terminal:

```powershell
Invoke-WebRequest http://localhost:5080/health
```

La respuesta esperada es HTTP 200 con el texto `Healthy`. El endpoint verifica que el proceso responde; todavía no comprueba una base de datos.

## Próximos pasos

- Definir el modelo de usuarios y publicaciones.
- Adaptar registro, login JWT y catálogos de provincias/localidades desde IdeasProyectos.
- Adaptar el importador GeoRef para cargar el catálogo en la base propia.
- Agregar EF Core, migraciones y PostgreSQL.
- Dockerizar la API y PostgreSQL con nombres, volúmenes y puertos propios.
- Crear la app Flutter y conectarla exclusivamente a la API.

.NET 8 se conserva inicialmente para mantener coherencia con el proyecto de referencia. Revisar la versión objetivo y su soporte antes del despliegue.

