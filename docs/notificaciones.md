# Notificaciones de posibles coincidencias — API

Implementación sin Firebase ni cambios en Flutter. Una notificación es persistente y pertenece al Mascotero identificado en el JWT. No se recibe el destinatario desde el cliente.

## Recorrido

1. `PublicacionesController` llama a `PublicacionService.CrearAsync`.
2. `PublicacionRepository.Agregar` agrega el aviso y una `NotificacionPendiente`. `GuardarAsync` persiste ambos atómicamente.
3. `ProcesarNotificaciones`, un `BackgroundService` dentro de la API, consulta la cola al iniciar y cada 10 segundos cuando no hay trabajo. No requiere otro contenedor.
4. `NotificacionService` delega el procesamiento transaccional en `NotificacionRepository`. La selección comparte `CoincidenciasConsulta` con el listado existente.
5. Por cada candidato de otro mascotero se insertan dos notificaciones, una por autor. `PublicacionId` siempre es el aviso propio del destinatario; `PublicacionCoincidenteId` es el candidato.
6. La app puede consultar los endpoints protegidos, mostrar la campana y abrir el detalle propio. Esa integración queda pendiente.

Se mantienen las reglas: activa, tipo opuesto (1↔2 o 3↔4), misma especie/localidad, al menos un atributo no nulo coincidente. Hallazgo entre 3 días antes y 30 después del extravío; adopción no exige fecha. Se excluyen notificaciones entre avisos del mismo autor. No se analizan imágenes.

## Persistencia y reintentos

- `Notificaciones`: ID, destinatario, ambas publicaciones, título/mensaje, creación UTC y lectura UTC nullable. Índice único por destinatario y pareja orientada de publicaciones.
- `NotificacionesPendientes`: publicación y fecha de encolado. La migración no encola avisos históricos. Un aviso nuevo sí puede coincidir con uno anterior.
- Cada lote procesa hasta 100 parejas, con hasta 200 notificaciones. Todos los candidatos se procesan, no solo los primeros resultados de la pantalla.
- El lote, ambas notificaciones y la eliminación de la tarea se confirman en una transacción. Una caída revierte el lote; otro intento continúa omitiendo parejas ya procesadas.
- Un bloqueo transaccional PostgreSQL evita que varias instancias procesen simultáneamente la cola. El índice único y `ON CONFLICT` impiden duplicados por reintentos o por procesar la pareja inversa.
- Abrir el detalle o consultar coincidencias no genera notificaciones. La carga de fotos no dispara otras notificaciones.
- Un error se registra y se reintenta en 10 segundos. El aviso ya creado no se pierde. El tiempo de entrega puede aumentar con la cola; no se garantiza entrega instantánea.
- Resolver un aviso antes de su procesamiento excluye ese aviso. Las notificaciones ya generadas se conservan como historial; el detalle informa su estado actual. Una resolución concurrente puede ocurrir después de la selección del lote.

## Contrato para Flutter

Todas las rutas requieren `Authorization: Bearer ACCESS_TOKEN`.

| Método y ruta | Respuesta |
| --- | --- |
| GET `/api/notificaciones?pagina=1&tamanoPagina=20&soloNoLeidas=false` | Página `{items,total,pagina,tamanoPagina}` |
| GET `/api/notificaciones/no-leidas/cantidad` | `{ "cantidad": 3 }` |
| PATCH `/api/notificaciones/{id}/leer` | 204, sin body |
| PATCH `/api/notificaciones/leer-todas` | 204, sin body |

Cada item contiene `id`, `publicacionId`, `publicacionCoincidenteId`, `titulo`, `mensaje`, `fechaCreacion`, `fechaLectura`. `fechaLectura: null` significa no leída. Leer otra vez no modifica la primera fecha. Un ID ajeno o inexistente devuelve 404. Páginas desde 1, máximo 50 items, página máxima 1.000.000; parámetros inválidos → 400. Sin JWT → 401.

Se conserva una fila por pareja y destinatario; el contador cuenta esas filas, no publicaciones agrupadas. `publicacionId` permite agrupar visualmente, pero la API lista notificaciones individuales paginadas. Si se necesita agrupación global paginada, debe agregarse esa consulta antes de implementar esa presentación; agrupar solo una página no da el total global.

## Validación

Desde la raíz del repositorio:

```powershell
docker compose up -d --build huellacerca_api
docker compose run --rm --no-deps huellacerca_tools run --project HuellaCerca.Notificaciones.Tests
docker compose run --rm --no-deps huellacerca_tests python /tests/test_notificaciones.py
docker compose run --rm --no-deps huellacerca_tests python /tests/test_coincidencias.py
```

La prueba .NET crea una base temporal, aplica migraciones y la elimina en `finally`. Requiere permiso PostgreSQL para crear bases (disponible en el entorno Docker local). Prueba 205 candidatos en varios lotes, reintentos/contextos nuevos, concurrencia, aislamiento, lecturas y rollback. La prueba HTTP crea tres cuentas y avisos de prueba en una localidad sin avisos, resuelve sus publicaciones y cierra sus sesiones al finalizar; conserva ese historial de prueba.

Migración: `20260924202330_NotificacionesCoincidencias`. El servicio de migraciones de Compose la aplica antes de iniciar la API. No requiere variables ni credenciales nuevas.
