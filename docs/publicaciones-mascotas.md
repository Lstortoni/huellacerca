# Publicaciones de mascotas: modelo inicial

Implementados: entidades, EF Core, DTO, interfaces, repositorio, servicios y controllers. Flutter incluye búsqueda, detalle, creación con una foto opcional y resolución exclusiva del autor. Ver [configuración y flujo de fotos R2](fotos-r2.md).

## Relaciones

- Un Mascotero crea muchas PublicacionesMascotas. Identifica al autor del aviso, no necesariamente al dueño del animal.
- Una PublicacionMascota tiene cero o una Foto.
- La publicación tiene su propia Localidad; su provincia se obtiene mediante Localidad.Provincia. No duplica ProvinciaId ni utiliza obligatoriamente la localidad del perfil.

## Datos del aviso

PublicacionMascota guarda tipo Perdida/Encontrada/Adopcion/BuscoAdoptar, tipo de mascota Perro/Gato/Otro, nombre opcional, descripción, fecha del suceso, localidad, zona aproximada, información de contacto, fecha de creación UTC y estado Activa/Resuelta. Para ambos tipos de adopción se usa FechaCreacion, y Resuelta indica que el caso finalizó. Los avisos existentes de tipo 3 conservan su tipo; no se convierten automáticamente a BuscoAdoptar.

FechaSuceso es DateOnly? (PostgreSQL date nullable) porque describe el día indicado por la persona, sin hora ni conversión de zona horaria. Los enums se guardan como enteros explícitos con restricciones de valores en PostgreSQL.

FotoPublicacion guarda Id, PublicacionMascotaId y ObjectKey. FotoService controla autorización, procesamiento, almacenamiento R2 y limpieza. No guarda binarios en PostgreSQL.

## Persistencia

Tablas publicaciones_mascotas y fotos_publicaciones, incorporadas en la migración PublicacionesMascotas. EF configura claves foráneas, longitudes máximas e índices de localidad/estado/fecha y autor. No permite borrar una localidad o mascotero con publicaciones asociadas. El borrado físico de una publicación eliminaría sus filas de fotografías en cascada; marcarla Resuelta no borra nada.

La migración FotoUnicaR2 elimina Orden y agrega un índice único por publicación. El DTO devuelve `foto: null` o `{id, url}`. La creación sigue siendo JSON; la foto se envía después por un PUT multipart separado.

## Flujo de la API

PublicacionesController recibe el DTO y obtiene MascoteroId del JWT para crear o resolver. IPublicacionService se resuelve como PublicacionService en Program.cs. El servicio valida y utiliza IPublicacionRepository (PublicacionRepository), que persiste con AppDbContext/EF. El servicio transforma entidades en PublicacionDto y el controller devuelve JSON.

- POST /api/publicaciones: JWT, devuelve 201 y Location del detalle. Crea Activa, nombre opcional, descripción entre 10 y 3000 caracteres (sin contar espacios externos), contacto obligatorio y localidad activa. Zona opcional solo para BuscoAdoptar. Fecha del suceso obligatoria y no futura para tipos 1/2; para 3/4 se guarda null. Tipo 4 ignora el nombre del animal.
- GET /api/publicaciones: público, filtros opcionales por tipo de publicación, tipo de mascota, provincia, localidad, mascotero, zona (texto parcial sin distinguir mayúsculas), estado y fechas inclusivas: día del suceso para tipos 1/2 y día de publicación en Argentina para 3/4. Sin estado incluye activas y resueltas. Paginación: 20 por defecto, máximo 100; orden fecha de creación descendente e ID para desempatar.
- GET /api/publicaciones/{id}: público, incluye el contacto que el autor ingresó para el aviso; no expone email de la cuenta ni rutas internas de archivos. Inexistente: 404.
- PATCH /api/publicaciones/{id}/resolver: JWT, sin cuerpo. Solo el autor (otro mascotero recibe 403). Devuelve 200 con estado Resuelta. Repetir como autor conserva el resultado y no borra el aviso.

Valores JSON numéricos: tipoPublicacion 1=Perdida, 2=Encontrada, 3=Adopcion (Doy en adopción), 4=BuscoAdoptar; tipoMascota 1=Perro, 2=Gato, 3=Otro; estado 1=Activa, 2=Resuelta.

La migración 20260917230913_PublicacionesAdopcion, generada con EF en Docker, amplía la restricción de PostgreSQL para permitir el valor 3, conservando los anteriores. Reemplaza la versión manual pendiente y solo modifica esa restricción. Aplicar desde la raíz: `docker compose up -d --build huellacerca_api`. Compose reconstruye y ejecuta el servicio de migraciones antes de iniciar la API. Para revertir a la restricción anterior no pueden quedar filas de tipo 3.

Pruebas: docker compose run --rm --no-deps huellacerca_tests python /tests/test_publicaciones.py. Crea dos cuentas y siete avisos de prueba identificados por hc-pets-test-*; al terminar deja los avisos resueltos, sin borrar datos existentes. Ejemplos manuales en PruebasApi.md.

## Próximo bloque

### Características opcionales — backend

La migración `20260920223958_CaracteristicasMascota` agrega cinco columnas enteras nullable a `publicaciones_mascotas`: Tamano, Raza, Pelaje, ColorPredominante y ColorOjos. Las publicaciones anteriores quedan con null, sin modificar sus otros datos. Los enums están en MODEL/CaracteristicasMascota.cs; no son nuevas entidades ni tablas. Los IDs explícitos no deben renumerarse.

POST acepta números o null y permite omitir los campos. El servicio valida antes de mapearlos al modelo; EF los guarda con el repositorio existente. Detalle, listado y resolución devuelven los mismos valores. PostgreSQL también restringe rangos y combinaciones. Para Perro/Gato están disponibles los cinco; para Otro, Tamaño y ColorPredominante. El resto puede describirse en el texto del aviso. La regla depende de la especie y no del tipo de aviso, por lo que la API permite características opcionales también en adopciones.

GET `/api/publicaciones/caracteristicas?tipoMascota=1` es público y devuelve campos y opciones aptos para esa especie. El catálogo no incluye una opción numérica «No sé»: Flutter omite el campo cuando se elige Sin indicar. El endpoint no consulta la base ni requiere un repositorio nuevo. Flutter incorpora los DTO y los selectores al crear los cuatro tipos de aviso; el detalle muestra las características informadas y la búsqueda permite filtrar por ellas. La foto opcional se integra con R2; la IA sigue pendiente.

## Posibles coincidencias

GET `/api/publicaciones/{id}/coincidencias?pagina=1&tamanoPagina=5` requiere JWT del autor del aviso. Cruza Perdida ↔ Encontrada y Adopcion ↔ BuscoAdoptar, nunca mezcla ambos grupos.

Los candidatos deben estar activos, ser de la misma especie y localidad, y compartir al menos una característica informada. Los valores nulos no suman. Se ordena por cantidad de características coincidentes, luego por fecha de creación descendente e Id para desempatar. Se pagina en la base, con máximo 20 por consulta.

Para extravío/hallazgo, el hallazgo debe estar entre 3 días antes y 30 días después del extravío. Para adopción no hay límite de fechas: FechaSuceso es null y cuenta que el aviso siga activo. Un aviso de origen resuelto devuelve una lista vacía.

Flutter consulta debajo del detalle de los avisos propios activos, después de publicar y al reabrir. Muestra 5 candidatos y permite ver más en páginas de 10. Indica en qué características coinciden y permite abrir el detalle para contactar al autor. Las coincidencias son sugerencias, no una confirmación de identidad ni un reemplazo de la búsqueda manual.

Implementar almacenamiento y carga/consulta de imágenes opcionales, con validación de formato/tamaño y permisos. Edición, eliminación y reapertura de avisos no están incluidas en este bloque.

La migración BuscoAdoptarFechaOpcional habilita el tipo 4 y FechaSuceso nullable. Fue generada con EF y aplicada mediante Docker Compose; API reconstruida. Pruebas HTTP de los cuatro tipos aprobadas.
